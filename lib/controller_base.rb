require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require 'byebug'
require_relative './session'
require_relative './flash'

class ControllerBase
  TOKEN_LENGTH = 4

  def self.protect_from_forgery(options = {})
    prepend_before_filter(:verify_authenticity_token, options)
  end

  # def self.before_filter(method, options = {})
  #   prepend_before_filter(method, options)
  # end

  def self.prepend_before_filter(method, options = {})
    before_filters[:all].unshift(method)
    # before_filters.each do |action, filters|
    #   filters.unshift(method)
    # end
  end

  def self.before_filters
    @@before_filters ||= Hash.new { |hash, key| hash[key] = [] }
  end


  attr_reader :req, :res, :params, :session, :flash
  # Setup the controller
  #
  def initialize(req, res, route_params = {} )
    @req, @res = req, res
    @params = req.params.merge(route_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise 'double render' if already_built_response?
    res.status = 302
    res['Location'] = url
    clean_up
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise 'double render' if already_built_response?
    res['Content-type'] = content_type
    res.body = [content]
    clean_up
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    set_form_authenticity_token!
    controller_name = self.class.to_s.underscore
    file_name = "views/#{controller_name}/#{template_name}.html.erb"
    begin
      html_erb = File.read(file_name)
    rescue Errno::ENOENT => e
      raise 'No such view' unless file_name =~ "_controller"
      file_name.gsub('_controller', '')
      retry
    end
    render_content(ERB.new(html_erb).result(binding), 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  def form_authenticity_token
    session['X-CSRF-Token'] ||= SecureRandom.urlsafe_base64(TOKEN_LENGTH)
  end

  def set_form_authenticity_token!
    session['X-CSRF-Token'] = SecureRandom.urlsafe_base64(TOKEN_LENGTH)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    run_before_filters(name)
    self.send(name)
    render(name) unless already_built_response?
  end

    private
    attr_writer :already_built_response

    def clean_up
      session.store_session(res)
      flash.store_flash(res)
      @already_built_response = true
    end

    def run_before_filters(action_name)
      self.class.before_filters[action_name].each do |filter|
        self.send(filter)
      end
      self.class.before_filters[:all].each do |filter|
        self.send(filter)
      end
    end

    def verify_authenticity_token(options = {})
      return if req.request_method.downcase.to_sym == :get
      unless verified_request?
        puts "CSRF ATTACK"
        unverified_request
      end
    end

    def verified_request?
      params['authenticity_token'] &&
        session['X-CSRF-Token'] == params['authenticity_token']
    end

    def unverified_request
      raise "CSRF ATTACK"
    end
end
