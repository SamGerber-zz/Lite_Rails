class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern, @http_method, @controller_class, @action_name =
      pattern, http_method, controller_class, action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    req.request_method.downcase.to_sym == http_method && req.path =~ @pattern
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    @controller_class.new(req, res, route_params(req)).invoke_action(action_name)
  end

  def route_params(req)
    match_data = req.path.match(@pattern)
    route_params = match_data.names.each.with_object( {} ) do |key, params|
      params[key] = match_data[key.to_sym]
    end
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&prc)
    instance_eval(&prc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.find { |route| route.matches?(req) }
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    route = match(req)
    if route
      route.run(req, res)
    else
      res.status = 404
      res.body = ["<html><body><h1>404 Not Found</h1></body></html>"]
    end
  end
end
