require_relative 'weak-hash'

module Fix
  # A simple analogue to a dynamic variable. Give it a hash of
  # :name => initial_values, and you can query the current
  # value by sending :name, or rebind by sending :rebind_name.
  #
  # dv = DynVar.new({:foo? => true, :bar => 1})
  # dv.foo?.should be_true
  # dv.bar.should == 1
  # dv.rebind_bar(2)
  # dv.bar.should == 2
  # dv.rebind_bar(3) {
  #   dv.bar.should == 3
  # }
  # dv.bar.should == 2
  # dv.bar.unbind_bar
  # dv.bar.should == 1
  class DynVar
    def initialize(names_values_hash)
      @properties = Hash.new
      names_values_hash.each{|k,v|
        @properties[k] = [v]
      }
    end

    def method_missing(m, *a, &b)
      if /rebind_([[:alnum:]]+\??\z)/.match(m.to_s) then
        rebind($1.to_sym, a[0])
        if block_given? then
          b.call
          unbind($1.to_sym)
        end
        value_of($1.to_sym)
      elsif @properties.has_key?(m)
        value_of(m)
      elsif /unbind_([[:alnum:]]+\??\z)/.match(m.to_s) then
          unbind($1.to_sym)
      else
        super(m, a, b)
      end
    end

    private
    def rebind(val_sym, new_val)
      @properties[val_sym] = @properties[val_sym].push(new_val)
      value_of(val_sym)
    end

    def unbind(val_sym)
      @properties[val_sym].pop
    end

    def value_of(val_sym)
      @properties[val_sym].last
    end
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
      @vars = DynVar.new({
                           :changed? => changed,
                           :running? => running,
                           :visited => visited
                         })
    end

    def cache
      @mutable_cache
    end

    def changed?
      return @vars.changed?
    end

    def running?
      return @vars.running?
    end

    def visited
      return @vars.visited
    end

    def rebind_changed(bool)
      @vars.rebind_changed?(bool)
    end

    def rebind_running(bool)
      @vars.rebind_running?(bool)
    end

    def rebind_visited(bool)
      @vars.rebind_visited(bool)
    end

    def run(x, bottom, &unary_block)
      is_cached = cache.has_key?(x)
      cached = cached_or_else(x, ->{bottom})
      should_run = running?
      if (is_cached and not should_run) then
        cached
      elsif (should_run and cached_or_else(visited, x))
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
