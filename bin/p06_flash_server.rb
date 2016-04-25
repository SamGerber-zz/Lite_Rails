
require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
require_relative '../lib/flash'
require_relative '../lib/session'
require 'byebug'

class FlashesController < ControllerBase
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
end

router = Router.new
router.draw do
  get Regexp.new("^/flashes$"), FlashesController, :index
  get Regexp.new("^/flashes/now$"), FlashesController, :now
  get Regexp.new("^/flashes/later$"), FlashesController, :later
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  puts req.cookies
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

Rack::Server.start(
 app: app,
 Port: 3000
)
