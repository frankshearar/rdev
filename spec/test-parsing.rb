require 'rdev/parser'
require 'rdev/stream.rb'

module DerParser
  describe "Parsing" do
    it "should accept the empty language" do
      Parser.eps.parse(StringStream.new('')).should == Set[]
    end

    it "should accept a token" do
      Parser.literal('f').parse(StringStream.new('f'), Identity.new, false, true).should == Set['f']
    end
  end
end
