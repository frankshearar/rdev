require_relative 'fixed-point'
require_relative 'memoize'
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

    def compact
      self
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

    def compact
      self
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
    attr_reader :token_class

    def initialize(predicate, token_class)
      @predicate = predicate
      @token_class = token_class
    end

    def ==(obj)
      return false unless !obj.nil? and obj.token_parser?

      if (predicate != obj.predicate) then
        return false
      end

      if (token_class != obj.token_class) then
        return false
      end
      true
    end

    def token_parser?
      true
    end

    def compact
      self
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
      token_matching(Equals.new(literal), :literal)
    end

    def self.token_matching(predicate, token_class)
      TokenParser.new(predicate, token_class)
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
          empty?(x.left_parser) and empty?(x.right_parser)
        elsif x.sequence?
          empty?(x.first_parser) or empty?(x.second_parser)
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
          nullable?(x.left_parser) or nullable?(x.right_parser)
        elsif x.sequence?
          nullable?(x.first_parser) and nullable?(x.second_parser)
        elsif x.reducer?
          nullable?(x.parser)
        else
          raise "nullable? not defined for #{parser.class.name}"
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
      raise "Not implemented yet for #{self.class.name}"
    end

    def derive(input_token)
      raise "Not implemented yet for #{self.class.name}"
    end

    def parse(input, compact = Identity.new, steps = false, debug = false)
      puts("debug: #{self.class.name}") if debug

      if (steps or steps == 0) then return self end
      if not input.next? then return self.parse_null end

      c = input.next
      rest = input.remaining
      dl_dc = self.derive(c)
      l_prime = dl_dc.memo_compact

      l_prime.parse(input.remaining,
                    compact,
                    if steps then steps - 1 else steps end,
                    debug)
    end

    def parse_null(parser = self)
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
          parser.left_parser.parse_null.merge(parser.right_parser.parse_null)
        elsif parser.sequence? then
          first_parser.parse_null.zip(second_parser.parse_null)
        elsif parser.reduction? then
          parser.parser.parse_null.collect {|t|
            parser.reduction_function.call(t)
          }
        end
      }
    end
  end

  class UnionParser < Parser
    attr_reader :left_parser
    attr_reader :right_parser

    def initialize(left_parser, right_parser)
      @left_parser = left_parser
      @right_parser = right_parser
    end

    def union?
      true
    end

    def ==(obj)
      return false if obj.nil?
      return false unless obj.union?
      (left_parser == obj.left_parser) and (right_parser == obj.right_parser)
    end

    def compact
      if self.empty? then
        Parser.empty
      elsif self.nullable? then
        EpsilonPrimeParser.new(self.parse_null)
      elsif left_parser.empty? then
        right_parser.memo_compact
      elsif right_parser.empty? then
        left_parser.memo_compact
      else
        left_parser.memo_compact.or(right_parser.memo_compact)
      end
    end

    def derive(input_token)
      left_parser.derive(input_token).or(right_parser.derive(input_token))
    end
  end

  class SequenceParser < Parser
    attr_reader :first_parser
    attr_reader :second_parser

    def initialize(first_parser, second_parser)
      @first_parser = first_parser
      @second_parser = second_parser
    end

    def sequence?
      true
    end

    def ==(obj)
      return false if obj.nil?
      return false unless obj.sequence?

      (first_parser == obj.first_parser) and (second_parser == obj.second_parser)
    end

    def compact
      if self.empty? then
        Parser.empty
      elsif self.nullable? then
        EpsilonPrimeParser.new(self.parse_null)
      elsif first_parser.nullable? then
        ReductionParser.new(second_parser.memo_compact, Cat.with_object(first_parser))
      elsif second_parser.nullable? then
        ReductionParser.new(first_parser.memo_compact, HeadCat.with_object(second_parser))
      else
        first_parser.memo_compact.then(second_parser.memo_compact)
      end
    end
  end

  class ReductionParser < Parser
    attr_reader :parser
    attr_reader :reduction_function

    def initialize(parser, reduction_function)
      @parser = parser
      @reduction_function = reduction_function
    end

    def ==(obj)
      return false unless !obj.nil? and obj.respond_to?(:reducer?) and obj.reducer?

      # Doing this the long-winded way gives us nice line numbers,
      # and an easy debug hook
      if (parser != obj.parser) then
        return false
      end

      if (reduction_function != obj.reduction_function) then
        return false
      end

      true
    end

    def reducer?
      true
    end

    def compact
      if @parser.empty?
        Parser.empty
      elsif self.nullable? then
        EpsilonPrimeParser.new(self.parse_null)
      elsif @parser.empty? then
        Parser.empty
      elsif @parser.nullable? then
        EpsilonPrimeParser.new(@parser.parse_null.collect(@parser.reduction_function))
      elsif @parser.sequence? and @parser.first_parser.nullable? then
        t = @parser.first_parser
        ReductionParser.new(@parser.second_parser.memo_compact, Cat.with_object(t))
      elsif @parser.reducer? then
        ReductionParser.new(@parser.parser.compact,
                            Compose.new(@reduction_function, @parser.reduction_function))
      else
        ReductionParser.new(@parser.memo_compact, @reduction_function)
      end
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

    def compact
      parser.memo_compact
    end

    def derive(input_token)
      parser.derive(input_token)
    end
  end

  # An object that represents a formalised Proc. Useful when you want to
  # check for equality between function-like things.
  class Reduction
    def call(input)
      raise "Not implemented yet for #{self.class.name}"
    end
  end

  class Identity < Reduction
    def ==(obj)
      !obj.nil? and (obj.class == self.class)
    end

    def call(input)
      input
    end
  end

  class Equals < Reduction
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

  class Compose < Reduction
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

  class Cat < Reduction
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
end
