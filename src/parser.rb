module DerParser

  class DerivativeParser
    # Forward declaration
  end

  class EmptyParser < DerivativeParser
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

  class EpsilonParser < DerivativeParser
    def ==(obj)
      obj.eps?
    end

    def eps?
      true
    end

    def derivative(input_token)
      DerivativeParser.empty
    end
  end

  class TokenParser < DerivativeParser
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
      return DerivativeParser.eps if input_token == @expected_token
      DerivativeParser.empty
    end
  end

  class DerivativeParser
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

    def token(predicate, token_class)
      TokenParser.new(predicate, token_class)
    end

    def derivative(input_token)
      raise "Not implemented yet for #{self.class.name}"
    end
  end

  class UnionParser < DerivativeParser
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

  class SequenceParser < DerivativeParser
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
end
