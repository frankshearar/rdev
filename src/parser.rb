require_relative 'fixed-point'

module DerParser

  class Parser
    # Forward declaration
  end

  class EmptyParser < Parser
    def ==(obj)
      obj.empty?
    end

    def empty?
      true
    end

    def derivative(input_token)
      self
    end
  end

  class EpsilonParser < Parser
    def ==(obj)
      obj.eps?
    end

    def eps?
      true
    end

    def derivative(input_token)
      Parser.empty
    end
  end

  class TokenParser < Parser
    attr_reader :expected_token

    def initialize(expected_token, tokenClass)
      @expected_token = expected_token
    end

    def ==(obj)
      obj.token_parser?
    end

    def token_parser?
      true
    end

    def derivative(input_token)
      return Parser.eps if input_token == @expected_token
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

    def empty
      self.empty
    end

    def eps
      self.eps
    end

    def empty?
      false
    end

    def eps?
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

    def nullable?(parser = self)
      Fix::LeastFixedPoint.run(parser, false) { |x|
        if x.empty?
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

    def token(predicate, token_class)
      TokenParser.new(predicate, token_class)
    end

    def union(alternate_parser)
      UnionParser.new(self, alternate_parser)
    end

    def then(following_parser)
      SequenceParser.new(self, following_parser)
    end

    def derivative(input_token)
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
  end

  class ReductionParser
    def initialize(parser, reduction_function)
      @parser = parser
      @reduction_function = reduction_function
    end
  end
end
