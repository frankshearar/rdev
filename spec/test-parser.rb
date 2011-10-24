require_relative '../src/parser.rb'

module DerParser
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
      DerivativeParser.new.token('foo', :lit).should_not be_empty
    end

    it "eps parser should be marked as such" do
      DerivativeParser.eps.should be_eps
    end

    it "other parsers should not be marked as eps" do
      DerivativeParser.empty.should_not be_eps
      DerivativeParser.new.token('foo', :lit).should_not be_eps
    end

    # it "token should return a parser that can consume a single token" do
    #   DerivativeParser.new.token('foo').parse('foo').should == ??
    # end


  end

  describe "Derivatives" do
    it "D_c(0) == 0" do
      DerivativeParser.empty.derivative('a').should be_empty
    end

    it "D_c(eps) == 0" do
      DerivativeParser.eps.derivative('a').should be_empty
    end

    it "D_c(c) == eps" do
      DerivativeParser.new.token('f', :lit).derivative('f').should be_eps
    end

    it "D_c(c') == empty if c != c'" do
      DerivativeParser.new.token('a', :lit).derivative('b').should be_empty
    end

    # it "D_c(A union 0) == D_c(A)" do
    #   # D_c(A union 0) == D_c(A)
    #   token_parser = DerivateParser.new.token('foo', :lit)
    #   derivative = token_parser.union(DerivativeParser.empty).derivative('a')
    #   derivative.should == token_parser.derivative
    # end

    # it "D_c(0 union A) == D_c(A)" do
    #   token_parser = DerivateParser.new.token('foo', :lit)
    #   derivative = DerivativeParser.empty.union(token_parser).derivative('a')
    #   derivative.should == token_parser.derivative
    # end

    # it "D_c(0 union 0) == 0" do
    #   token_parser = DerivateParser.new.token('foo', :lit)
    #   derivative = DerivativeParser.empty.union(DerivativeParser.empty).derivative('a')
    #   derivative.should be_empty
    # end

    # it "D_c(A union B) == D_c(A) union D_c(B)" do
    #   fail
    # end

    # it "D_c(NotNullable then B) == D_c(NotNullable) then B" do
    #   fail
    # end

    # it "D_c(Nullable then B) == (D_c(Nullable) then B) union D_c(B)" do
    #   b = DerivativeParser.new.token('bar', :lit)
    #   nullable = DerivativeParser.new.token('foo', :lit).union(DerivativeParser.empty)
    #   language = a.then(b)
    #   language.derivative('a').should == nullable.derivative('a').then(b)
    # end

    # it "D_c(A not) == D_c(A) not" do
    #   token_parser = DerivateParser.new.token('foo', :lit)
    #   token_parser.not.derivative('a').should == token_parser.derivative('a').not
    # end
  end
end
