require 'json'

class Session
  COOKIE_NAME = '_rails_lite_app'

  attr_reader :cookie

  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @req = req
    @cookie = req.cookies[COOKIE_NAME]
    @cookie = @cookie ? JSON.parse( req.cookies[COOKIE_NAME] ) : {}
  end

  def [](key)
    cookie.fetch(key) { nil }
  end

  def []=(key, val)
    cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.set_cookie(COOKIE_NAME, path: '/', value: cookie.to_json)
  end
end
