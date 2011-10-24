module DerParser

  class DerivativeParser
    # Forward declaration
  end

  class EmptyParser < DerivativeParser
    def empty?
      true
    end

    def derivative(input_token)
      self
    end
  end

  class EpsilonParser < DerivativeParser
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

    def token(predicate, token_class)
      TokenParser.new(predicate, token_class)
    end

    def derivative(input_token)
      raise "Not implemented yet for #{self.class.name}"
    end
  end

  class UnionParser
    def initialize(left_parser, right_parser)
      @left_parser = left_parser
      @right_parser = right_parser
    end
  end

  class SequenceParser
    def initialize(first_parser, second_parser)
      @first_parser = first_parser
      @second_parser = second_parser
    end
  end
end
