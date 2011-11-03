require 'weakref'

class WeakHash
  def initialize
    @hash = Hash.new
  end

  def has_key?(key)
    return false unless @hash.has_key?(key)

    if @hash[key].respond_to?(:weakref_alive?) then
      @hash[key].weakref_alive?
    else
      true
    end
  end

  def [](key)
    return @hash[key] if @hash.has_key?(key)
    nil
  end

  def []=(key, new_val)
    # You can't attach a finaliser to some kinds of objects.
    # Try, but if new_val is one such - a FixNum, say - then
    # store new_val directly.
    begin
      wrapped_value = WeakRef.new(new_val)
    rescue ArgumentError
      wrapped_value = new_val
    end
    @hash[key] = wrapped_value
  end
end
