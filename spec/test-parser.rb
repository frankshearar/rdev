describe "DerivativeParser" do
  it "empty should be a flyweight" do
    DerivativeParser.empty.should == DerivativeParser.empty
  end

  it "eps should be a flyweight" do
    DerivativeParser.eps.should == DerivativeParser.eps
  end

  it "empty parser should be marked as such" do
    DerivativeParser.empty.should be_empty
  end

  it "other parsers should not be marked as empty" do
    DerivativeParser.eps.should_not be_empty
    DerivativeParser.token('foo', :lit).should_not be_empty
  end

  it "eps parser should be marked as such" do
    DerivativeParser.eps.should be_eps
  end

  it "other parsers should not be marked as eps" do
    DerivativeParser.empty.should_not be_eps
    DerivativeParser.token('foo', :lit).should_not be_eps
  end

  it "token should return a parser that can consume a single token" do
    DerivativeParser.new.token('foo').parse('foo').should == ??
  end

  it "derivative of the empty parser is the empty parser" do
    DerivativeParser.empty.derivative.should be_empty
  end

  it "derivative of the eps parser is the empty parser" do
    DerivativeParser.eps.derivative.should be_empty
  end

  it "derivative of a token parser is the eps parser" do
    DerivativeParser.new.token('foo', :lit).derivative.should be_eps
  end

  it "derivative of a parser unioned with the empty parser is the derivative of the non-empty parser" do
    # D(A union 0) == D(A)
    token_parser = DerivateParser.new.token('foo', :lit)
    derivative_of_right_empty = token_parser.union(DerivativeParser.empty).derivative
    derivative_of_right_empty.should == token_parser.derivative

    derivative_of_left_empty = DerivativeParser.empty.union(token_parser).derivative
    derivative_of_left_empty.should == token_parser.derivative

    derivative_of_both_empty = DerivativeParser.empty.union(DerivativeParser.empty).derivative
    derivative_of_both_empty.should be_empty
  end
end
