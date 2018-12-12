$redis = Redis.new url: HOSTS[:redis]
module RedisHelper
  extend self
  def cache_key(key, val, expire = 1.hours)
    $redis.set(key, val)
    expire.nil? and return val
    $redis.expire(key, expire.to_i)
    val
  end

  %w(incr get del sadd smembers srem spop smove).each do |a|
    define_method a do |*key|
      $redis.send(a, *key)
    end
  end

  def cache(key, expire = 1.hours, &block)
    val = $redis.get(key) and return val
    val = (value = block.call).respond_to?(:to_json) && !value.is_a?(String) ? value.to_json : value
    raise "cached data must be a string" if !val.is_a?(String)
    cache_key(key, val, expire)
  end

  def cache_to_tomorrow(key, &block)
    cache(key, expire_at_tomorrow, &block)
  end

  def cache_json(key, expire = 1.hours, &block)
    val = cache(key, expire, &block)
    JSON.parse(val) rescue {}
  end

  def cache!(key, val)
    cache_key(key, val, nil)
  end

  def expire_at_tomorrow
    Date.tomorrow.to_datetime.to_i - Time.now.to_datetime.to_i
  end

  def get_value_from_redis_object(obj, cached_symbol, original)
    raise "The second params must have a call method" unless original.respond_to?(:call)
    obj.send(cached_symbol).value || obj.send("#{cached_symbol}=", original.call)
  end

  def jsoned_object_from_redis_object(obj, cached_symbol, original, json_type = {})
    JSON.parse(get_value_from_redis_object(obj, cached_symbol, original)).presence || json_type
  rescue => e
    puts "ERROR: #{e.message}"
    json_type
  end
end
