require 'rdev/weak-hash.rb'

module DerParser
  # A basic memoiser: mix it into a class, and you can memoise message sends.
  # Usage:
  # class FunWithNumbers
  #   include Memo
  #   def succ(n)
  #     call(->x{x + 1}, n)
  #   end
  #
  #   def pred(n)
  #     call(pred_helper(n))
  #   end
  #
  #   def pred_helper(n)
  #     n - 1
  #   end
  # end
  #
  # fun = FunWithNumbers
  # fun.succ(1)
  # fun.pred(1)
  class Memo
    def initialize
      @cache = WeakHash.new
    end

    def call(method_name, rcvr, *args, &block)
      all_args = args.dup
      all_args << block if block_given?

      key = [method_name, rcvr, all_args]
      if @cache.has_key?(key) then
        @cache[key]
      else
        result = if block_given? then
                   rcvr.send(method_name, *args, &block)
                 else
                   rcvr.send(method_name, *args)
                 end
        @cache[key] = result
      end
    end
  end

  # Mix this into a class to provide memoisation: automatically
  # memoise any method :foo by calling :memo_foo. (Methods with bangs
  # are never memoised.)
  module Memoizer
    def method_missing(m, *a, &b)
      if /memo_([a-zA-Z][[[:alnum:]]_]*\??\z)/.match(m.to_s) then
        memo.call($1, self, *a, &b)
      else
        super(m, a, b)
      end
    end

    private
    def memo
      @memo = Memo.new if @memo.nil?
      @memo
    end
  end
end
