require 'rdev/fixed-point'
require 'rdev/memoize'
require 'set'

module DerParser
  class Parser
    # Forward declaration
  end

  # The language that accepts the empty set.
  class EmptyParser < Parser
    def ==(obj)
      !obj.nil? and obj.empty_parser?
    end

    def empty_parser?
      true
    end

    def derive(input_token)
      self
    end
  end

  # The language that accepts the empty string.
  class EpsilonParser < Parser
    def ==(obj)
      !obj.nil? and obj.eps?
    end

    def eps?
      true
    end

    def derive(input_token)
      Parser.empty
    end
  end

  # An empty string that produces a tree. Only appears during parsing.
  class EpsilonPrimeParser < EpsilonParser
    attr_reader :parse_trees

    def initialize(parse_trees)
      @parse_trees = parse_trees
    end

    def ==(obj)
      !obj.nil? and obj.respond_to?(:eps_prime?) and obj.eps_prime?
    end

    def eps_prime?
      true
    end
  end

  # The language that accepts input satisfying some predicate (i.e.,
  # a unary block that returns a boolean).
  class TokenParser < Parser
    attr_reader :predicate

    def initialize(predicate)
      @predicate = predicate
    end

    def ==(obj)
      return false unless !obj.nil? and obj.token_parser?

      if (predicate != obj.predicate) then
        return false
      end

      true
    end

    def token_parser?
      true
    end

    def derive(input_token)
      return Parser.eps if @predicate.call(input_token)
      Parser.empty
    end
  end

  class Parser
    include Memoizer

    @@EMPTY = EmptyParser.new
    @@EPS = EpsilonParser.new

    def self.empty
      @@EMPTY
    end

    def self.eps
      @@EPS
    end

    def self.literal(literal)
      token_matching(Equals.new(literal))
    end

    def self.token_matching(predicate)
      TokenParser.new(predicate)
    end

    def empty
      self.empty
    end

    def eps
      self.eps
    end

    def empty_parser?
      false
    end

    def eps?
      false
    end

    def eps_prime?
      false
    end

    def reducer?
      false
    end

    def token_parser?
      false
    end

    def union?
      false
    end

    def sequence?
      false
    end

    # Does parser accept the empty set?
    def empty?(parser = self)
      LeastFixedPoint.run(parser, false) { |x|
        if x.empty_parser?
          true
        elsif x.eps?
          false
        elsif x.token_parser?
          false
        elsif x.union?
          empty?(x.left) and empty?(x.right)
        elsif x.sequence?
          empty?(x.first) or empty?(x.second)
        elsif x.reducer?
          empty?(x.parser)
        else
          raise "empty? not defined for #{parser.class.name}"
        end
      }
    end

    # Does parser accept the empty string?
    def nullable?(parser = self)
      LeastFixedPoint.run(parser, false) { |x|
        if x.empty_parser?
          false
        elsif x.eps?
          true
        elsif x.token_parser?
          false
        elsif x.union?
          nullable?(x.left) or nullable?(x.right)
        elsif x.sequence?
          nullable?(x.first) and nullable?(x.second)
        elsif x.reducer?
          nullable?(x.parser)
        else
          raise "nullable? not defined for #{parser.class.name}"
        end
      }
    end

    def recognises?(stream)
      trampoline(self, stream) { |parser, stream|
        if not stream.next? then
          nullable?
        else
          ->{derive(stream.next).recognises?(stream.remaining)}
        end
      }
    end

    def or(alternate_parser)
      union(alternate_parser)
    end

    def union(alternate_parser)
      UnionParser.new(self, alternate_parser)
    end

    def then(following_parser)
      SequenceParser.new(self, following_parser)
    end

    def compact
      Compact.new.call(self)
    end

    def derive(input_token)
      raise "derive not implemented yet for #{self.class.name}"
    end

    def parse(input_stream, compact = Identity.new, steps = false, debug = false)
      puts("debug: #{self.class.name}") if debug

      if (steps or steps == 0) then return self end
      if not input_stream.next? then
        puts("debug: no more input for #{self.class.name}")
        return self.parse_null
      end

      c = input_stream.next
      rest = input_stream.remaining
      dl_dc = self.derive(c)
      l_prime = dl_dc.compact

      l_prime.parse(input_stream.remaining,
                    compact,
                    if steps then steps - 1 else steps end,
                    debug)
    end

    def parse_null(parser = self)
      puts "#{self.class.name}.parse_null"
      empty_set = Set.new
      LeastFixedPoint.run(parser, empty_set) { |x|
        if parser.empty? then
          empty_set
        elsif parser.eps_prime? then
          parser.parser
        elsif parser.eps? then
          Set[parser]
        elsif parser.token_parser? then
          empty_set
        elsif parser.union? then
          parser.left.parse_null.merge(parser.right.parse_null)
        elsif parser.sequence? then
          first.parse_null.zip(second.parse_null)
        elsif parser.reduction? then
          parser.parser.parse_null.collect {|t|
            parser.reducer.call(t)
          }
        end
      }
    end

    private
    def trampoline(*args, &block)
      result = block.call(*args)
      while result.kind_of?(Proc) do
        result = result.call
      end
      result
    end
  end

  class UnionParser < Parser
    attr_reader :left
    attr_reader :right

    def initialize(left, right)
      @left = left
      @right = right
    end

    def union?
      true
    end

    def ==(obj)
      return false if obj.nil?
      return false unless obj.union?

      # a | b == b | a
      same_order = (left == obj.left) and (right == obj.right)
      diff_order = (left == obj.right) and (right == obj.left)
      same_order or diff_order
    end

    def derive(input_token)
      left.derive(input_token).or(right.derive(input_token))
    end
  end

  class SequenceParser < Parser
    attr_reader :first
    attr_reader :second

    def initialize(first, second)
      @first = first
      @second = second
    end

    def sequence?
      true
    end

    def ==(obj)
      return false if obj.nil?
      return false unless obj.sequence?

      (first == obj.first) and (second == obj.second)
    end

    def derive(input_token)
      if first.nullable? then
        second.derive(input_token).or(first.derive(input_token).then(second))
      else
        first.derive(input_token).then(second)
      end
    end
  end

  class ReductionParser < Parser
    attr_reader :parser
    attr_reader :reducer

    def initialize(parser, reducer)
      @parser = parser
      @reducer = reducer
    end

    def ==(obj)
      return false unless !obj.nil? and obj.respond_to?(:reducer?) and obj.reducer?

      # Doing this the long-winded way gives us nice line numbers,
      # and an easy debug hook
      if (parser != obj.parser) then
        return false
      end

      if (reducer != obj.reducer) then
        return false
      end

      true
    end

    def reducer?
      true
    end

    def derive(input_token)
      @parser.derive(input_token)
    end
  end

  # A stand-in for a parser not yet defined. Handy for self-recursion.
  class DelegateParser < Parser
    attr_accessor :parser

    def initialize(parser = nil)
      @parser = parser
    end

    def ==(obj)
      return false if obj.nil?
      [:eps?, :empty?, :eps_prime?, :token_parser?, \
       :union?, :sequence?, :reducer?].inject(true) { |answer, name|
        answer or (self.send(name) and obj.send(name))
      }
    end

    def empty_parser?
      parser.empty_parser?
    end

    def eps?
      parser.eps?
    end

    def eps_prime?
      parser.eps_prime?
    end

    def first
      parser.first
    end

    def left
      parser.left
    end

    def right
      parser.right
    end

    def second
      parser.second
    end

    def token_parser?
      parser.token_parser?
    end

    def union?
      parser.union?
    end

    def reducer?
      parser.reducer?
    end

    def sequence?
      parser.sequence?
    end

    def derive(input_token)
      parser.derive(input_token)
    end
  end

  # An object that represents a formalised Proc. Useful when you want to
  # check for equality between function-like things.
  class Callable
    def call(input)
      raise "Not implemented yet for #{self.class.name}"
    end
  end

  class Identity < Callable
    def ==(obj)
      !obj.nil? and (obj.class == self.class)
    end

    def call(input)
      input
    end
  end

  class Equals < Callable
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def ==(obj)
      !obj.nil? and obj.respond_to?(:token) and (@token == obj.token)
    end

    def call(input)
      @token == input
    end
  end

  class Compose < Callable
    attr_reader :f
    attr_reader :g

    def initialize(f_proc_like, g_proc_like)
      raise "Cannot use a #{f_proc_like.class.name} for composition" unless f_proc_like.respond_to?(:call)
      raise "Cannot use a #{g_proc_like.class.name} for composition" unless g_proc_like.respond_to?(:call)
      @f = f_proc_like
      @g = g_proc_like
    end

    def ==(obj)
      !obj.nil? and (obj.respond_to?(:f)) and (obj.respond_to?(:g)) and (f == obj.f) and (g == obj.g)
    end

    def call(input)
      @f.call(@g.call(input))
    end
  end

  class Cat < Callable
    attr_reader :seed

    def initialize(array)
      @seed = array
    end

    def ==(obj)
      !obj.nil? and (obj.class == self.class) and (@seed == obj.seed)
    end

    def self.with_array(array)
      self.new(array)
    end

    def self.with_object(obj)
      self.new([obj])
    end

    def call(input)
      @seed + [input]
    end
  end

  class HeadCat < Cat
    def call(input)
      [input] + @seed
    end
  end

  class Compact < Callable
    include Memoizer

    def compact(parser)
      call(parser)
    end

    def call(parser)
      if parser.empty_parser?
        parser
      elsif parser.eps?
        parser
      elsif parser.empty?
        Parser.empty
      elsif parser.nullable?
        EpsilonPrimeParser.new(parser.parse_null)
      elsif parser.token_parser?
        parser
      elsif parser.union? 
        if parser.left.empty?
          compact(parser.right)
        elsif parser.right.empty?
          compact(parser.left)
        else
          compact(parser.left).or(compact(parser.right))
        end
      elsif parser.sequence?
        if parser.first.nullable?
          ReductionParser.new(compact(parser.second), Cat.new(parser.first))
        elsif parser.second.nullable?
          ReductionParser.new(compact(parser.first), HeadCat.new(parser.second))
        else
          compact(parser.first).then(compact(parser.second))
        end
      elsif parser.reducer?
        if parser.parser.empty?
          Parser.empty
        elsif parser.parser.nullable?
          EpsilonPrimeParser.new(parser.parser.parse_null.collect {|t| parser.reducer.call(t)})
        elsif parser.parser.sequence? and parser.parser.first.nullable?
          ReductionParser.new(compact(parser.parser.second), Cat.new(parser.parser.first))
        elsif parser.parser.reducer?
          ReductionParser.new(compact(parser.parser), Compose.new(parser.reducer, parser.parser.reducer))
        else
          ReductionParser.new(compact(parser.parser), parser.reducer)
        end
      end
    end
  end
end
