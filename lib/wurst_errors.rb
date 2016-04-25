class WurstErrors
  EDITOR_FORMAT = "atm://open?url=file://%{file}&line=%{line}"
  SNIPPET_LENGTH = 11

  attr_reader :next_app_in_stack

  def initialize(next_app_in_stack)
    @next_app_in_stack = next_app_in_stack
  end

  def call(env)
    begin
      next_app_in_stack.call(env)
    rescue Exception => e
      res = build_response(e)
      res.finish
    end
  end

  def build_response(e)
    res = Rack::Response.new
    res.status = 418
    res['Content-type'] = 'text/html'
    source_location = e.backtrace_locations.first
    context = generate_context(e)

    html_erb = <<-HTML
      <H1>Exception: <%= e.message %></H1>
      <br/>
        <h3>#{stack_trace_link(source_location)}</h3>
        <pre><%= context.join("\n") %></pre>
      <br/>
      <strong>Backtrace</strong>
      <br/>
      <% e.backtrace_locations.each do |location| %>
        <%= stack_trace_link(location) %>
        <br/>
      <% end %>
      <br/>
    HTML

    res.body = [ERB.new(html_erb).result(binding)]
    res
  end

  def editor_url(path:, line: 1)
    EDITOR_FORMAT.gsub("%{file}", path).gsub("%{line}", String(line))
  end

  def stack_trace_link(location)
    absolute_path = location.absolute_path
    path = location.path
    line = location.lineno
    label = location.label

    html = <<-HTML
      <a href=" #{ editor_url(path: absolute_path, line: line) } ">
        #{absolute_path}:#{line}
      </a>:in  "<strong>#{html_escape(label)}</strong>"
    HTML

    html.html_safe
  end

  def generate_context(e)
    location = e.backtrace_locations.first
    path = location.path
    line = location.lineno - 1
    first_line = [line - (SNIPPET_LENGTH / 2), 0].max
    context = File.readlines(path)[first_line, SNIPPET_LENGTH]

    context = context.map.with_index do |trace_item, index|
      trace_item.prepend("#{(index + line - 4).to_s.rjust(7)}|  ")
    end
    context[(SNIPPET_LENGTH / 2)][0..2] = "-->"

    context
  end

  def html_escape(string)
    escaped_string = string.gsub(/&/, "&amp")
    escaped_string = escaped_string.gsub(/</, "&lt")
    escaped_string.gsub(/>/, "&gt")
  end
end
