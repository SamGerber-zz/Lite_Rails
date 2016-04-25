require 'byebug'

class Flash
  include Enumerable
  FLASH_NAME = '_flash'

  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @req = req
    #debugger
    @flash_now = req.cookies[FLASH_NAME]
    @flash_now = @flash_now ? JSON.parse( req.cookies[FLASH_NAME] ) : Hash.new { [] }
    @flash_now = @flash_now.each.with_object( Hash.new { [] }) do |(k,v), memo|
      memo[k.to_sym] = v
    end
    @flash_keep = Hash.new { [] }
  end

  def now
    @flash_now
  end

  def [](purpose)
    flashes[purpose]
  end

  def []=(purpose, message)
    @flash_keep[purpose] = message
  end

  def []=(purpose, message)
    @flash_keep[purpose] = message
  end

  def keep(*purposes)
    if purposes.empty?
      @flash_keep.merge!(@flash_now) { |_, now_v, keep_v| now_v + keep_v }
    else
      purposes.each do |purpose|
        @flash_keep[purpose] += @flash_now[purpose]
      end
    end
  end

  def each(&prc)
    flashes.each(&prc)
  end

  def store_flash(res)
    res.set_cookie(FLASH_NAME, path: '/', value: @flash_keep.to_json)
  end

  def inspect
    flashes
  end

    private

    def flashes
      @flash_now.merge(@flash_keep) { |_, now_v, keep_v| now_v + keep_v }
    end
end
