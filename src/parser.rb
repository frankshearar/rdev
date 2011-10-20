class DerivativeParser
  # Forward declaration
end

class EmptyParser < DerivativeParser
end

class EpsilonParser < DerivativeParser
end

class TokenParser < DerivativeParser
  def initialize(predicate, tokenClass)
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

  def token(predicate, tokenClass)
    TokenParser.new(predicate, tokenClass)
  end
end

class UnionParser
  def initialize(leftParser, rightParser)
    @leftParser = leftParser
    @rightParser = rigtParser
  end
end

class SequenceParser
  def initialize(firstParser, secondParser)
    @firstParser = firstParser
    @secondParser = secondParser
  end
end
