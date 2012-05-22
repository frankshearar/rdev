require 'rdev/parser.rb'

module DerParser
  describe "Parser" do
    it "empty should be a flyweight" do
      Parser.empty.should == Parser.empty
      Parser.new.empty.should == Parser.empty
    end

    it "eps should be a flyweight" do
      Parser.eps.should == Parser.eps
      Parser.new.eps.should == Parser.eps
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

    it "should compact eps* to itself" do
      t = Parser.literal('a').then(Parser.literal('b'))
      eps_star = EpsilonPrimeParser.new(Set[])
      eps_star.compact.should == eps_star
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

    it "should compact A or 0 to A compact" do
      a = Parser.literal('a').then(Parser.eps)
      union = a.union(Parser.empty)
      union.compact.should == a.compact
    end

    it "should compact A or B to A compact or B compact" do
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

    it "should compact eps then A to A compact" do
      a = Parser.literal('a').then(Parser.eps)
      seq = Parser.eps.then(a)
      cmpct = seq.compact
      cmpct.should be_reducer
      cmpct.parser.should == a.compact
    end

    it "should compact A then eps to A compact" do
      a = Parser.eps.then(Parser.literal('a'))
      seq = Parser.eps.then(a)
      cmpct = seq.compact
      cmpct.should be_reducer
      cmpct.parser.should == a.compact
    end

    it "should compact a delegate parser as the parser to which it delegates" do
      a = Parser.eps.then(Parser.literal('a'))
      delegate = DelegateParser.new
      delegate.parser = a
      delegate.compact.should == a.compact
    end

    it "should compact a reduction parser's parser" do
      a = Parser.eps.then(Parser.literal('a'))
      reduction = ReductionParser.new(a, Identity.new)
      cmpct = reduction.compact
      cmpct.should be_reducer
      cmpct.parser.should == a.second
    end

    it "should compact nested reductions as a composition of the reduction functions" do
      a = Parser.literal('a')
      inner = ReductionParser.new(a, ->x{x * 2})
      outer = ReductionParser.new(inner, ->x{x + 1})

      cmpct = outer.compact
      # Compacting red(token) --> red(token), with the same reducing function
      # Compacting red(red(token)) --> red2(token) where red2's reducing
      # function is the composition of the two original functions.

      cmpct.reducer.call(1).should == 3
      cmpct.should be_reducer
      cmpct.parser.should be_reducer
      cmpct.parser.parser.should be_token_parser
    end
  end

  describe "Equality: empty parser" do
    it "should == empty parser" do
      EmptyParser.new.should == EmptyParser.new
    end

    it "should == itself" do
      e = EmptyParser.new
      e.should == e
    end

    it "should not == nil" do
      EmptyParser.new.should_not == nil
    end

    it "should not == eps parser" do
      empty = EmptyParser.new
      eps = EpsilonParser.new

      empty.should_not == eps
      eps.should_not == empty
    end

    it "should == parser delegating to empty" do
      Parser.empty.should == DelegateParser.new(Parser.empty)
    end
  end

  describe "Equality: eps parser" do
    it "should not == nil" do
      EpsilonParser.new.should_not == nil
    end

    it "should == itself" do
      e = EpsilonParser.new
      e.should == e
    end

    it "should == eps parser" do
      EpsilonParser.new.should == EpsilonParser.new
    end

    it "should not == nil" do
      EpsilonParser.new.should_not == nil
    end

    it "should == parser delegating to eps" do
      Parser.eps.should == DelegateParser.new(Parser.eps)
    end
  end

  describe "Equality: eps* parser" do
    it "should == another eps* parser on the same language" do
      EpsilonPrimeParser.new(Set[]).should == EpsilonPrimeParser.new(Set[])
    end

    it "should not == eps* parser on a different language" do
      EpsilonPrimeParser.new(Set[]).should == EpsilonPrimeParser.new(Set[1])
    end

    it "should not == eps" do
      EpsilonPrimeParser.new(Set[]).should_not == EpsilonParser.new
    end

    it "should not == nil" do
      EpsilonPrimeParser.new(Set[]).should_not == nil
    end

    it "eps* parser should == parser delegating to eps*" do
      EpsilonPrimeParser.new(Set[]).should == DelegateParser.new(EpsilonPrimeParser.new(Set[]))
    end
  end

  describe "Equality: token parser" do
    it "should not == nil" do
      Parser.literal('foo').should_not == nil
    end

    it "should == itself" do
      f = Parser.literal('foo')
      f.should == f
    end

    it "should == parser consuming == token" do
      TokenParser.new('foo').should == TokenParser.new('foo')
    end

    it "should not == parser consuming different == tokens" do
      pred_1 = Identity.new
      pred_2 = Adder.new(1)

      TokenParser.new(pred_1).should_not == TokenParser.new(pred_2)
      TokenParser.new(pred_2).should_not == TokenParser.new(pred_1)
    end

    it "should not == nil" do
      TokenParser.new('foo').should_not == nil
    end
  end

  describe "Equality: union parser" do
    it "should not == nil" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == nil
    end

    it "should == itself" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      u.should == u
    end

    it "should == when parts are ==" do
      a = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      b = UnionParser.new(Parser.empty, TokenParser.new('foo'))

      a.should == b
      b.should == a
    end

    it "should == when parts are ==, regardless of order" do
      a = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      b = UnionParser.new(TokenParser.new('foo'), Parser.empty)

      a.should == b
      b.should == a
    end

    it "should not == empty" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == Parser.empty
      Parser.empty.should_not == u
    end

    it "should not == eps" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == Parser.eps
      Parser.eps.should_not == u
    end

    it "should not == eps*" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == EpsilonPrimeParser.new(Set[])
      EpsilonPrimeParser.new(Set[]).should_not == u
    end

    it "should not == token parsers" do
      u = UnionParser.new(Parser.empty, TokenParser.new('foo'))
      t = TokenParser.new('foo')
      u.should_not == t
      t.should_not == u
    end

    it "should not == nil" do
      UnionParser.new(Parser.empty, TokenParser.new('foo')).should_not == nil
    end
  end

  describe "Equality: sequence parser" do
    it "should not == nil" do
      s = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      s.should_not == nil
    end

    it "should == itself" do
      s = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      s.should == s
    end

    it "should == when parts are ==" do
      a = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      b = SequenceParser.new(Parser.empty, TokenParser.new('foo'))

      a.should == b
      b.should == a
    end

    it "should not == empty" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == Parser.empty
      Parser.empty.should_not == u
    end

    it "should not == eps" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == Parser.eps
      Parser.eps.should_not == u
    end

    it "should not == eps*" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      u.should_not == EpsilonPrimeParser.new(Set[])
      EpsilonPrimeParser.new(Set[]).should_not == u
    end

    it "should not == token parsers" do
      u = SequenceParser.new(Parser.empty, TokenParser.new('foo'))
      t = TokenParser.new('foo')
      u.should_not == t
      t.should_not == u
    end

    it "should not == nil" do
      SequenceParser.new(Parser.empty, TokenParser.new('foo')).should_not == nil
    end
  end

  describe "Equality: reduction parser" do
    it "should not == nil" do
      ReductionParser.new(Parser.empty, ->x{x}).should_not == nil
    end

    it "should not == empty parser" do
      ReductionParser.new(Parser.empty, ->x{x}).should_not == Parser.empty
    end

    it "should not == eps parser" do
      ReductionParser.new(Parser.eps, ->x{x}).should_not == Parser.eps
    end

    it "should not == eps* parser" do
      prime = EpsilonPrimeParser.new(Set[])
      ReductionParser.new(prime, ->x{x}).should_not == prime
    end

    it "should not == token parser" do
      t = Parser.literal('foo')
      ReductionParser.new(t, ->x{x}).should_not == t
    end

    it "should not == union parser" do
      u = Parser.literal('foo').or(Parser.literal('bar'))
      ReductionParser.new(u, ->x{x}).should_not == u
    end

    it "should not == sequence parser" do
      s = Parser.literal('foo').then(Parser.literal('bar'))
      ReductionParser.new(s, ->x{x}).should_not == s
    end

    it "should not == delegate parser" do
      d = DelegateParser.new(Parser.literal('foo'))
      ReductionParser.new(d, ->x{x}).should_not == d
    end

    it "should not == reduction parser of different grammar but same reduction" do
      red = ->x{x}
      r_foo = ReductionParser.new(Parser.literal('foo'), red)
      r_bar = ReductionParser.new(Parser.literal('bar'), red)
      r_foo.should_not == r_bar
    end

    it "should not == reduction parser of same grammar but different reduction" do
      red_1 = ->x{x}
      red_2 = ->x{x.to_s} # red_2 = ->x{x} results in red_1 == red_2 !
      p_1 = ReductionParser.new(Parser.empty, red_1)
      p_2 = ReductionParser.new(Parser.empty, red_2)
      p_1.should_not == p_2
    end

    it "should == reduction parser of same grammar and same reduction" do
      red = ->x{x}
      ReductionParser.new(Parser.empty, red).should == ReductionParser.new(Parser.empty, red)
    end
  end

  describe "Equality: delegate parser" do
    it "should == delegated parser of same language (empty)" do
      DelegateParser.new(Parser.empty).should == Parser.empty
    end

    it "should == delegated parser of same language (eps)" do
      DelegateParser.new(Parser.eps).should == Parser.eps
    end

    it "should == delegated parser of same language (eps*)" do
      DelegateParser.new(EpsilonPrimeParser.new(Set[])).should == EpsilonPrimeParser.new(Set[])
    end

    it "should == delegated parser of same language (token parser)" do
      t = Parser.literal('foo')
      DelegateParser.new(t).should == t
    end

    it "should == delegated parser of same language (union parser)" do
      u = Parser.literal('foo').or(Parser.literal('bar'))
      DelegateParser.new(u).should == u
    end

    it "should == delegated parser of same language (sequence parser)" do
      s = Parser.literal('foo').then(Parser.literal('bar'))
      DelegateParser.new(s).should == s
    end

    it "should == delegated parser of same language (reduction parser)" do
      r = ReductionParser.new(Parser.literal('foo'), ->x{x})
      DelegateParser.new(r).should == r
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

    it "D_c(A union B) == D_c(A) union D_c(B)" do
      a = Parser.literal('foo')
      b = Parser.literal('bar')
      language = a.or(b)

      language.derive('f').should == a.derive('f').or(b.derive('f'))
    end

    it "D_c(NotNullable then B) == D_c(NotNullable) then B" do
      a = Parser.literal('foo')
      b = Parser.literal('bar')
      language = a.then(b)
      language.derive('f').should == a.derive('a').then(b)
    end

    it "D_c(Nullable then B) == (D_c(Nullable) then B) union D_c(B)" do
      b = Parser.literal('bar')
      nullable = Parser.literal('foo').union(Parser.eps)
      language = nullable.then(b)
      language.derive('a').should == b.derive('a').or(nullable.derive('a').then(b))
    end

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

  describe DelegateParser do
    it "should delegate left to the underlying parser" do
      u = UnionParser.new(Parser.empty, Parser.eps)
      d = DelegateParser.new(u)
      d.left.should == u.left
    end

    it "should delegate right to the underlying parser" do
      u = UnionParser.new(Parser.empty, Parser.eps)
      d = DelegateParser.new(u)
      d.right.should == u.right
    end
  end

  describe Equals do
    it "should return true for == objects" do
      Equals.new(1).call(1).should be_true
    end

    it "should return false for not == objects" do
      Equals.new(1).call(2).should be_false
    end

    it "should not == nil" do
      Equals.new(1).should_not == nil
    end

    it "should == itself" do
      e = Equals.new(1)
      e.should == e
    end

    it "should == Equals with equal-valued parameter" do
      Equals.new(1).should == Equals.new(1)
    end

    it "should not == Equals with different-valued parameter" do
      Equals.new(1).should_not == Equals.new(2)
    end
  end

  describe Compose do
    it "should permit composition of Callables" do
      Compose.new(Identity.new, Identity.new).call(1).should == 1
      Compose.new(Adder.new(1), Adder.new(2)).call(3).should == 6
    end

    it "should permit composition of Procs with Callables" do
      Compose.new(->x{x * 2}, Adder.new(1)).call(3).should == 8
    end

    it "should permit composition of Callables with Procs" do
      Compose.new(Adder.new(1), ->x{x * 2}).call(3).should == 7
    end

    it "should permit composition of Procs" do
      Compose.new(->x{x * 2}, ->x{x + 1}).call(3).should == 8
    end

    it "should not == nil" do
      Compose.new(Cat.with_object(1), Cat.with_object(2)).should_not == nil
    end

    it "should == itself" do
      c = Compose.new(Cat.with_object(1), Cat.with_object(2))
      c.should == c
    end

    it "should == composition of same-value functions" do
      a = Compose.new(Cat.with_object(1), Cat.with_object(2))
      b = Compose.new(Cat.with_object(1), Cat.with_object(2))
      a.should == b
    end

    it "should == composition of equivalent-value functions" do
      a = Compose.new(Cat.with_object(1), Cat.with_object(2))
      b = Compose.new(Cat.with_array([1]), Cat.with_array([2]))
      a.should == b
    end

    it "should not == when f differs" do
      a = Compose.new(Cat.with_object(1), Cat.with_object(2))
      b = Compose.new(Cat.with_object(2), Cat.with_object(2))
      a.should_not == b
    end

    it "should not == when g differs" do
      a = Compose.new(Cat.with_object(1), Cat.with_object(2))
      b = Compose.new(Cat.with_object(1), Cat.with_object(1))
      a.should_not == b
    end

    it "should not == when f and g differ" do
      a = Compose.new(Cat.with_object(1), Cat.with_object(2))
      b = Compose.new(Cat.with_object(2), Cat.with_object(1))
      a.should_not == b
    end
  end

  describe Identity do
    it "should define the identity function" do
      Identity.new.call(1).should == 1
      Identity.new.call("a string").should == "a string"
      Identity.new.call(:a_symbol).should == :a_symbol
    end

    it "should not == nil" do
      Identity.new.should_not == nil
    end

    it "should == itself" do
      i = Identity.new
      i.should == i
    end

    it "should == another Identity" do
      Identity.new.should == Identity.new
    end
  end

  describe Cat do
    it "should allow catenation of objects" do
      Cat.with_object(1).call(2).should == [1, 2]
    end

    it "should allow catenation of arrays with objects" do
      Cat.with_array([1]).call(2).should == [1, 2]
    end

    it "should allow treating of an array as an item" do
      Cat.with_object([1]).call(2).should == [[1], 2]
    end

    it "should not be == to nil" do
      Cat.with_object(1).should_not == nil
    end

    it "should be == to itself" do
      c = Cat.with_object(1)
      c.should == c
    end

    it "should be == to a Cat with the same parameters" do
      Cat.with_object(1).should == Cat.with_object(1)
    end

    it "should be == to a Cat with equivalent parameters" do
      Cat.with_object(1).should == Cat.with_array([1])
    end

    it "should not be == to a Cat with different parameters" do
      Cat.with_object(1).should_not == Cat.with_object(2)
    end
  end

  describe HeadCat do
    it "should allow adding an object to the front of a singleton array" do
      HeadCat.with_object(1).call(2).should == [2, 1]
    end

    it "should allow adding an object to the front of an array" do
      HeadCat.with_array([1]).call(2).should == [2, 1]
    end

    it "should allow treating of an array as an item" do
      HeadCat.with_object([1]).call(2).should == [2, [1]]
    end

    it "should not be == to nil" do
      HeadCat.with_object(1).should_not == nil
    end

    it "should be == to itself" do
      c = HeadCat.with_object(1)
      c.should == c
    end

    it "should be == to a Cat with the same parameters" do
      HeadCat.with_object(1).should == HeadCat.with_object(1)
    end

    it "should be == to a Cat with equivalent parameters" do
      HeadCat.with_object(1).should == HeadCat.with_array([1])
    end

    it "should not be == to a Cat with different parameters" do
      HeadCat.with_object(1).should_not == HeadCat.with_object(2)
    end
  end

  class Adder
    attr_accessor :increment

    def initialize(a_number)
      @increment = a_number
    end

    def call(a_number)
      a_number + @increment
    end
  end
end
