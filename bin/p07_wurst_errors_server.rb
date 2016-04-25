
require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
require_relative '../lib/flash'
require_relative '../lib/session'
require_relative '../lib/wurst_errors'
require 'byebug'

class ErrorsController < ControllerBase
  def index
    1.to_sym
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/$"), ErrorsController, :index
end



app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app_stack = Rack::Builder.new do
  use WurstErrors
  run app
end.to_app

Rack::Server.start(
 app: app_stack,
 Port: 3000
)
