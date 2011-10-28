require_relative '../src/parser.rb'

module DerParser
  describe "Parser" do
    it "empty should be a flyweight" do
      Parser.empty.should == Parser.empty
    end

    it "eps should be a flyweight" do
      Parser.eps.should == Parser.eps
    end

    it "empty parser should be marked as such" do
      Parser.empty.should be_empty_parser
    end

    it "other parsers should not be marked as empty" do
      Parser.eps.should_not be_empty_parser
      Parser.literal('foo').should_not be_empty_parser
    end

    it "eps parser should be marked as such" do
      Parser.eps.should be_eps
    end

    it "other parsers should not be marked as eps" do
      Parser.empty.should_not be_eps
      Parser.literal('foo').should_not be_eps
    end

    it "token should return a parser that can consume a single token" do
      Parser.literal('foo').should be_token_parser
    end
  end

  describe "Composition" do
    it "then produces a sequence parser" do
      Parser.empty.then(Parser.empty).should be_sequence
    end

    it "or produces a union parser" do
      Parser.empty.or(Parser.empty).should be_union
    end

    it "union produces a union parser" do
      Parser.empty.union(Parser.empty).should be_union
    end

    it "token produces a token parser" do
      Parser.token('foo', :lit).should be_token_parser
    end
  end

  describe "Equality" do
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
      a = UnionParser.new(Parser.empty, TokenParser.new('foo', :lit))
      b = UnionParser.new(Parser.empty, TokenParser.new('foo', :lit))

      a.should == b
      b.should == a
    end

    it "union parsers should not be == to empty" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo', :lit))
      u.should_not == Parser.empty
      Parser.empty.should_not == u
    end

    it "union parsers should not be == to eps" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo', :lit))
      u.should_not == Parser.eps
      Parser.eps.should_not == u
    end

    it "union parsers should not be == to token parsers" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo', :lit))
      t = TokenParser.new('foo', :lit)
      u.should_not == t
      t.should_not == u
    end

    it "sequence parsers should be == when their parts are ==" do
      a = SequenceParser.new(Parser.empty, TokenParser.new('foo', :lit))
      b = SequenceParser.new(Parser.empty, TokenParser.new('foo', :lit))

      a.should == b
      b.should == a
    end

    it "sequence parsers should not be == to empty" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo', :lit))
      u.should_not == Parser.empty
      Parser.empty.should_not == u
    end

    it "sequence parsers should not be == to eps" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo', :lit))
      u.should_not == Parser.eps
      Parser.eps.should_not == u
    end

    it "sequence parsers should not be == to token parsers" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo', :lit))
      t = TokenParser.new('foo', :lit)
      u.should_not == t
      t.should_not == u
    end
  end

  describe "Derivatives" do
    it "D_c(0) == 0" do
      Parser.empty.derivative('a').should be_empty_parser
    end

    it "D_c(eps) == 0" do
      Parser.eps.derivative('a').should be_empty_parser
    end

    it "D_c(c) == eps" do
      Parser.token('f', :lit).derivative('f').should be_eps
    end

    it "D_c(c') == empty if c != c'" do
      Parser.token('a', :lit).derivative('b').should be_empty_parser
    end

    # it "D_c(A union 0) == D_c(A)" do
    #   # D_c(A union 0) == D_c(A)
    #   token_parser = DerivateParser.token('foo', :lit)
    #   derivative = token_parser.union(Parser.empty).derivative('a')
    #   derivative.should == token_parser.derivative
    # end

    # it "D_c(0 union A) == D_c(A)" do
    #   token_parser = DerivateParser.token('foo', :lit)
    #   derivative = Parser.empty.union(token_parser).derivative('a')
    #   derivative.should == token_parser.derivative
    # end

    # it "D_c(0 union 0) == 0" do
    #   token_parser = DerivateParser.token('foo', :lit)
    #   derivative = Parser.empty.union(Parser.empty).derivative('a')
    #   derivative.should be_empty_parser
    # end

    # it "D_c(A union B) == D_c(A) union D_c(B)" do
    #   fail
    # end

    # it "D_c(NotNullable then B) == D_c(NotNullable) then B" do
    #   fail
    # end

    # it "D_c(Nullable then B) == (D_c(Nullable) then B) union D_c(B)" do
    #   b = Parser.literal('bar')
    #   nullable = Parser.literal('foo').union(Parser.empty)
    #   language = a.then(b)
    #   language.derive('a').should == nullable.derive('a').then(b)
    # end

    # it "D_c(A not) == D_c(A) not" do
    #   token_parser = Parser.literal('foo')
    #   token_parser.not.derive('a').should == token_parser.derive('a').not
    # end
  end

  describe "Is the language accepted by this parser the empty string?" do
    it "empty parser is not nullable" do
      Parser.empty.nullable?.should be_false
    end

    it "eps parser is nullable" do
      Parser.eps.nullable?.should be_true
    end
    
    it "token parser is not nullable" do
      Parser.literal('foo').nullable?.should be_false
    end

    it "union parser of non-nullable parsers is not nullable" do
      Parser.empty.union(Parser.empty).nullable?.should be_false
    end

    it "union of nullable parser with non-nullable parser is nullable" do
      Parser.eps.union(Parser.empty).nullable?.should be_true
    end

    it "union of non-nullable parser with nullable parser is nullable" do
      Parser.empty.union(Parser.eps).nullable?.should be_true
    end

    it "union of two nullable parsers is nullable" do
      Parser.eps.union(Parser.eps).nullable?.should be_true
    end

    it "two non-nullable parsers in sequence is not nullable" do
      Parser.empty.then(Parser.empty).nullable?.should be_false
    end

    it "two nullable parsers in sequence is nullable" do
      Parser.eps.then(Parser.eps).nullable?.should be_true
    end

    it "nullable parser followed by non-nullable parser is not nullable" do
      Parser.eps.then(Parser.empty).nullable?.should be_false
    end

    it "non-nullable parser followed by nullable parser is not nullable" do
      Parser.eps.then(Parser.empty).nullable?.should be_false
    end
  end

  describe "Is the language accepted by this parser the empty set?" do
    it "the empty parser accepts the empty set" do
      Parser.empty.empty?.should be_true
    end

    it "the eps parser does not accept the empty set" do
      Parser.eps.empty?.should be_false
    end

    it "a token parser does not accept the empty set" do
      Parser.literal('foo').empty?.should be_false
    end

    it "the union of two non-empty parsers does not accept the empty set" do
      Parser.eps.or(Parser.eps).empty?.should be_false
    end

    it "the union of two non-empty parsers does accepts the empty set" do
      Parser.empty.or(Parser.empty).empty?.should be_true
    end

    it "the union of a non-empty parser and an empty parser does not accept the empty set" do
      Parser.eps.or(Parser.empty).empty?.should be_false
      Parser.empty.or(Parser.eps).empty?.should be_false
    end

    it "the sequence of two non-empty parsers does not accept the empty set" do
      Parser.empty.then(Parser.empty).empty?.should be_true
    end

    it "the sequence of two non-empty parsers does not accept the empty set" do
      Parser.eps.then(Parser.eps).empty?.should be_false
    end

    it "the sequence of a non-empty parser and an empty parser accepts the empty set" do
      Parser.eps.then(Parser.empty).empty?.should be_true
      Parser.empty.then(Parser.eps).empty?.should be_true
    end
  end
end
