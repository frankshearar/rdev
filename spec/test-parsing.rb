require 'rdev/parser'
require 'rdev/stream.rb'

module DerParser
  describe "Parsing" do
    it "should recognise the empty language" do
      Parser.eps.recognises?(StringStream.new('')).should be_true
    end

    it "should recognise a literal" do
      Parser.literal('f').recognises?(StringStream.new('f')).should be_true
      Parser.literal('f').recognises?(StringStream.new('g')).should be_false
      Parser.literal('f').recognises?(StringStream.new('ff')).should be_false
    end

    it "should recognise a union" do
      a_or_b = Parser.literal('a').or(Parser.literal('b'))
      a_or_b.recognises?(StringStream.new('a')).should be_true
      a_or_b.recognises?(StringStream.new('b')).should be_true
      a_or_b.recognises?(StringStream.new('c')).should be_false
    end

    it "should recognise a sequence" do
      ab = Parser.literal('a').then(Parser.literal('b'))
      ab.recognises?(StringStream.new('ab')).should be_true
      ab.recognises?(StringStream.new('abc')).should be_false
    end

    it "should accept the empty language" do
      Parser.eps.parse(StringStream.new('')).should == Set[]
    end

    it "should accept a single token language" do
      Parser.literal('c').parse(StringStream.new('c')).should == Set['c']
    end
  end
end
