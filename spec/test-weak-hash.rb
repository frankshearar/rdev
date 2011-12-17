require 'rdev/weak-hash.rb'

describe WeakHash do
  before :each do
    @hash = WeakHash.new
  end

  it "should permit mapping to non-finalizable values" do
    @hash[:foo] = 1
    @hash[:foo].should == 1
  end

  it "should permit mapping to finalizable values" do
    # The local reference to obj keeps the WeakRef alive.
    obj = Object.new
    @hash[:foo] = obj
    @hash[:foo].should == obj
  end

  it "should claim to not map to a GCed object" do
    @hash[:foo] = Object.new
    ObjectSpace.garbage_collect
    @hash.has_key?(:foo).should be_false
  end

  it "should permit checking the presence of non-finalizable values" do
    @hash[:foo] = 1
    @hash.has_key?(:foo).should be_true
  end
end
