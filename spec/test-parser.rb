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

    it "literal produces a token parser" do
      Parser.literal('foo').should be_token_parser
    end
  end

  describe "Compaction" do
    it "should compact 0 to itself" do
      Parser.empty.compact.should == Parser.empty
    end

    it "should compact eps to itself" do
      Parser.eps.compact.should == Parser.eps
    end

    it "should compact a token parser to itself" do
      lit = Parser.literal('a')
      lit.compact.should == lit
    end

    it "should compact a nullable grammar to 0" do
      nullable = UnionParser.new(Parser.empty, Parser.empty)
      nullable.compact.should == Parser.empty
    end

    it "should compact 0 or A to A compact" do
      a = Parser.literal('a').then(Parser.eps)
      union = Parser.empty.union(a)
      union.compact.should == a.compact
    end

    it "should compact A union 0 parser to A compact" do
      a = Parser.literal('a').then(Parser.eps)
      union = a.union(Parser.empty)
      union.compact.should == a.compact
    end

    it "should compact A union B to A compact union B compact" do
      a = Parser.literal('a').then(Parser.eps)
      b = Parser.eps.then(Parser.literal('b'))
      a.or(b).compact.should == a.compact.or(b.compact)
    end

    it "should compact A then B to A compact then B compact" do
      a = Parser.literal('a').then(Parser.eps)
      b = Parser.eps.then(Parser.literal('b'))

      a.then(b).compact.should == a.compact.then(b.compact)
    end

    it "should compact a reduction of 0 to 0" do
      red_empty = ReductionParser.new(Parser.empty, ->x{x})
      red_empty.compact.should == Parser.empty
    end

    it "should compact a reduction of an empty language to 0" do
      red_empty = ReductionParser.new(UnionParser.new(Parser.empty, Parser.empty), ->x{x})
      red_empty.compact.should == Parser.empty
    end

    it "should compact an eps then something to the compaction of the something" do
      something = Parser.literal('a').then(Parser.eps)
      seq = Parser.eps.then(something)
      seq.compact.should == something.compact
    end

    it "should compact A then eps to A compact" do
      a = Parser.eps.then(Parser.literal('a'))
      seq = Parser.eps.then(a)
      seq.compact.should == a.compact
    end

    it "should compact a delegate parser as the parser to which it delegates" do
      something = Parser.eps.then(Parser.literal('a'))
      delegate = DelegateParser.new
      delegate.parser = something
      delegate.compact.should == something.compact
    end

    it "should compact a reduction parser's parser" do
      something = Parser.eps.then(Parser.literal('a'))
      reduction = ReductionParser.new(something, ->x{x})
      reduction.compact.reducer?.should be_true
      reduction.compact.parser.should == something.compact
    end

    it "should compact nested reductions as a composition of the reduction functions" do
      a = Parser.eps.then(Parser.literal('a'))
      inner = ReductionParser.new(a, ->x{x * 2})
      outer = ReductionParser.new(inner, ->x{x + 1})
      outer.compact.parser.should == a.compact
      outer.compact.reduction_function.call(1).should == 3
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
      Parser.empty.derive('a').should be_empty_parser
    end

    it "D_c(eps) == 0" do
      Parser.eps.derive('a').should be_empty_parser
    end

    it "D_c(c) == eps" do
      Parser.literal('f').derive('f').should be_eps
    end

    it "D_c(c') == empty if c != c'" do
      Parser.literal('a').derive('b').should be_empty_parser
    end

    it "D_c(A union 0) == D_c(A)" do
      token_parser = Parser.literal('foo')
      derivative = token_parser.union(Parser.empty).derive('a')
      derivative.compact.should == token_parser.derive('a').compact
    end

    it "D_c(0 union A) == D_c(A)" do
      token_parser = Parser.literal('foo')
      derivative = Parser.empty.union(token_parser).derive('a')
      derivative.compact.should == token_parser.derive('a')
    end

    it "D_c(0 union 0) == 0" do
      derivative = Parser.empty.union(Parser.empty).derive('a')
      derivative.compact.should be_empty_parser
    end

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

    it "D_c(reduction(A)) == D_c(A)" do
      a = Parser.literal('bar')
      red = ReductionParser.new(a, ->x{x})
      red.derive('a').should == a.derive('a')
      red.derive('bar').should == a.derive('bar')
    end

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

  # Need deriving before we can test parsing
  # describe "Parsing" do
  #   it "token parser should accept a token" do
  #     fail "Not implemented yet"
  #   end
  # end
end
