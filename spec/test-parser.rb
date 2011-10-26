require_relative '../src/parser.rb'

module DerParser
  describe "DerivativeParser:" do
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

  describe "Composition:" do
    it "then produces a sequence parser" do
      DerivativeParser.empty.then(DerivativeParser.empty).should be_sequence
    end

    it "union produces a union parser" do
      DerivativeParser.empty.union(DerivativeParser.empty).should be_union
    end

    it "token produces a token parser" do
      DerivativeParser.empty.token('foo', :lit).should be_token_parser
    end
  end

  describe "Equality:" do
    it "empty parsers should be ==" do
      EmptyParser.new.should == EmptyParser.new
    end

    it "empty parsers and eps parsers should not be ==" do
      empty = EmptyParser.new
      eps = EpsilonParser.new

      empty.should_not == eps
      eps.should_not == empty
    end

    it "eps parsers should be ==" do
      EpsilonParser.new.should == EpsilonParser.new
    end

    it "token parsers should be == when they consume == tokens" do
      TokenParser.new('foo', :lit).should == TokenParser.new('foo', :lit)
    end

    it "token parsers should not be == when they consume == tokens" do
      TokenParser.new('foo', :lit).should == TokenParser.new('bar', :lit)
      TokenParser.new('foo', :lit).should == TokenParser.new('foo', :literal)
    end

    it "union parsers should be == when their parts are ==" do
      a = UnionParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      b = UnionParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))

      a.should == b
      b.should == a
    end

    it "union parsers should not be == to empty" do
      u = UnionParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      u.should_not == DerivativeParser.empty
      DerivativeParser.empty.should_not == u
    end

    it "union parsers should not be == to eps" do
      u = UnionParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      u.should_not == DerivativeParser.eps
      DerivativeParser.eps.should_not == u
    end

    it "union parsers should not be == to token parsers" do
      u = UnionParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      t = TokenParser.new('foo', :lit)
      u.should_not == t
      t.should_not == u
    end

    it "sequence parsers should be == when their parts are ==" do
      a = SequenceParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      b = SequenceParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))

      a.should == b
      b.should == a
    end

    it "sequence parsers should not be == to empty" do
      u = SequenceParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      u.should_not == DerivativeParser.empty
      DerivativeParser.empty.should_not == u
    end

    it "sequence parsers should not be == to eps" do
      u = SequenceParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      u.should_not == DerivativeParser.eps
      DerivativeParser.eps.should_not == u
    end

    it "sequence parsers should not be == to token parsers" do
      u = SequenceParser.new(DerivativeParser.empty, TokenParser.new('foo', :lit))
      t = TokenParser.new('foo', :lit)
      u.should_not == t
      t.should_not == u
    end
  end

  describe "Derivatives:" do
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

  describe "Nullability:" do
    it "empty parser is not nullable" do
      DerivativeParser.empty.nullable?.should be_false
    end

    it "eps parser is nullable" do
      DerivativeParser.eps.nullable?.should be_true
    end
    
    it "token parser is not nullable" do
      DerivativeParser.new.token('foo', :lit).nullable?.should be_false
    end

    it "union parser of non-nullable parsers is not nullable" do
      DerivativeParser.empty.union(DerivativeParser.empty).nullable?.should be_false
    end

    it "union of nullable parser with non-nullable parser is nullable" do
      DerivativeParser.eps.union(DerivativeParser.empty).nullable?.should be_true
    end

    it "union of non-nullable parser with nullable parser is nullable" do
      DerivativeParser.empty.union(DerivativeParser.eps).nullable?.should be_true
    end

    it "union of two nullable parsers is nullable" do
      DerivativeParser.eps.union(DerivativeParser.eps).nullable?.should be_true
    end

    it "two non-nullable parsers in sequence is not nullable" do
      DerivativeParser.empty.then(DerivativeParser.empty).nullable?.should be_false
    end

    it "two nullable parsers in sequence is nullable" do
      DerivativeParser.eps.then(DerivativeParser.eps).nullable?.should be_true
    end

    it "nullable parser followed by non-nullable parser is not nullable" do
      DerivativeParser.eps.then(DerivativeParser.empty).nullable?.should be_false
    end

    it "non-nullable parser followed by nullable parser is not nullable" do
      DerivativeParser.eps.then(DerivativeParser.empty).nullable?.should be_false
    end
  end
end
