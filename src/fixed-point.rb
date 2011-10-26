module Fix
  class WeakHash < Hash
  end

  class LeastFixedPoint
    def self.run(x, bottom, &unary_block)
      lfp = self.new(Hash.new,
                     :error_changed,
                     false,
                     :error_visited)
      lfp.run(x, bottom, &unary_block)
    end

    def initialize(cache, changed, running, visited)
      @mutable_cache = cache
      @changed = [changed]
      @running = [running]
      @visited = [visited]
    end

    def cache
      @mutable_cache
    end
    
    def changed?
      return @changed.last
    end
    
    def running?
      return @running.last
    end

    def visited
      return @visited.last
    end

    def rebind_changed(bool)
      @changed.push(bool)
    end

    def rebind_running(bool)
      @running.push(bool)
    end

    def rebind_visited(bool)
      @visited.push(bool)
    end

    def unbind
      @changed.pop
      @running.pop
      @visited.pop
    end

    def run(x, bottom, &unary_block)
      is_cached = cache.has_key?(x)
      cached = cached_or_else(x, Proc.new {bottom})
      should_run = running?
      if (is_cached and not should_run) then
        cached
      elsif (should_run and cached_or_else(@visited, x))
        if is_cached then cached else bottom end
      elsif should_run
        visited[x] = true
        new_val = block.call(x)
        if new_val != cached then
          rebind_changed(true)
          cache[x] = new_val
        end
      elsif ((not is_cached) and (not should_run))
        rebind_changed(true)
        rebind_running(true)
        rebind_visited(WeakHash.new)
        v = bottom
        while changed? do
          rebind_changed(false)
          rebind_visited(WeakHash.new)
          v = unary_block.call(x)
        end
        v
      end
    end

    def cached_or_else(key, alternative)
      if @mutable_cache.has_key?(key) then
        @mutable_cache[key]
      else
        alternative
      end
    end
  end
end
