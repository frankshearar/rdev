require_relative 'fixed-point'

module DerParser

  class Parser
    # Forward declaration
  end

  # The language that accepts the empty set.
  class EmptyParser < Parser
    def ==(obj)
      obj.empty_parser?
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
      obj.eps?
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

  # The language that accepts input satisfying some predicate (i.e.,
  # a unary block that returns a boolean).
  class TokenParser < Parser
    attr_reader :predicate

    def initialize(predicate, tokenClass)
      @predicate = predicate
    end

    def ==(obj)
      obj.token_parser?
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
    @@EMPTY = EmptyParser.new
    @@EPS = EpsilonParser.new

    def self.empty
      @@EMPTY
    end

    def self.eps
      @@EPS
    end

    def self.literal(literal)
      token_matching(->x{x == literal}, :literal)
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
      Fix::LeastFixedPoint.run(parser, false) { |x|
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
        else
          empty?(x.parser)
        end
      }
    end

    # Does parser accept the empty string?
    def nullable?(parser = self)
      Fix::LeastFixedPoint.run(parser, false) { |x|
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
        else
          nullable?(x.parser) # ReductionParser
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
      return false unless obj.union?
      (left_parser == obj.left_parser) and (right_parser == obj.right_parser)
    end

    def compact
      if self.empty? then
        Parser.empty
      elsif left_parser.empty? then
        right_parser.compact
      elsif right_parser.empty? then
        left_parser.compact
      else
        left_parser.compact.or(right_parser.compact)
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
      return false unless obj.sequence?

      (first_parser == obj.first_parser) and (second_parser == obj.second_parser)
    end

    def compact
      if self.nullable? then
        Parser.empty
      elsif first_parser.nullable? then
        second_parser.compact
      elsif second_parser.nullable? then
        first_parser.compact
      else
        first_parser.compact.then(second_parser.compact)
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

    def reducer?
      true
    end

    def compact
      if @parser.empty?
        Parser.empty
      elsif @parser.reducer? then
        ReductionParser.new(@parser.parser.compact,
                            ->x{@reduction_function.call(@parser.reduction_function.call(x))})
      else
        ReductionParser.new(@parser.compact, @reduction_function)
      end
    end
  end

  # A stand-in for a parser not yet defined. Handy for self-recursion.
  class DelegateParser < Parser
    attr_accessor :parser

    def empty_parser?
      parser.empty_parser?
    end

    def eps?
      parser.eps?
    end

    def token_parser?
      parser.token_parser?
    end

    def union?
      parser.union?
    end

    def sequence?
      parser.sequence?
    end

    def compact
      parser.compact
    end

    def derive(input_token)
      parser.derive(input_token)
    end
  end
end
