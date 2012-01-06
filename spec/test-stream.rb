require 'rdev/stream.rb'

module DerParser
  describe StringStream do
    before :each do
      @stream = StringStream.new('foo')
    end

    it "should read a character" do
      @stream.next.should == 'f'
    end

    it "should iterate over the string" do
      @stream.next.should == 'f'
      @stream.next.should == 'o'
      @stream.next.should == 'o'
    end

    it "should raise an exception on the end of a stream" do
      @stream.next
      @stream.next
      @stream.next
      ->{@stream.next}.should raise_error(EndOfStream)
    end

    it "should permit querying for the end of a stream" do
      @stream.next
      @stream.next
      @stream.next?.should be_true
      @stream.next
      @stream.next?.should be_false
    end

    it "should allow access to the remaining input" do
      @stream.remaining.raw.should == 'foo'
      @stream.next
      @stream.remaining.raw.should == 'oo'
      @stream.next
      @stream.remaining.raw.should == 'o'
      @stream.next
      @stream.remaining.raw.should == ''
    end
  end
end
  
