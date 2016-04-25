
require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
require_relative '../lib/flash'
require_relative '../lib/session'
require_relative '../lib/wurst_errors'
require_relative '../lib/statty_assets'
require 'byebug'

class CsrfController < ControllerBase

  protect_from_forgery

  def index
    render :buttons
  end

  def now
    flash.now[:notice] = ["A message for now"]
    flash[:notice] = ["And one for later..."]
    render :buttons
  end

  def later
    flash.now[:notice] = ["A message for now"]
    flash[:notice] = ["And one for later..."]
    redirect_to "/flashes"
  end

  def token
    flash.now[:notice] = ["Token"]
    render :buttons
  end

  def no_token
    flash.now[:notice] = ["No Token"]
    render :buttons
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/flashes$"), CsrfController, :index
  post Regexp.new("^/flashes/token$"), CsrfController, :token
  post Regexp.new("^/flashes/no_token$"), CsrfController, :no_token
  get Regexp.new("^/flashes/now$"), CsrfController, :now
  get Regexp.new("^/flashes/later$"), CsrfController, :later
end



app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app_stack = Rack::Builder.new do
  use WurstErrors
  use StattyAssets
  run app
end.to_app

Rack::Server.start(
 app: app_stack,
 Port: 3000
)
