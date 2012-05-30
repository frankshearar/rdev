require 'rdev/parser'

describe Set do
  describe :singleton? do
    it "should return empty for the empty set" do
      Set[].should_not be_singleton
    end

    it "should return true for a 1-element set" do
      Set[1].should be_singleton
    end

    it "should return false for any set with more than 1 element" do
      Set[1,2].should_not be_singleton
      Set[1,2,3].should_not be_singleton
      Set[1,2,3,4].should_not be_singleton
    end
  end
end
