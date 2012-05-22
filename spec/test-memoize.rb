require 'rdev/memoize'

module DerParser
  class MemoTest
    attr_reader :calculation_count

    def initialize
      @calculation_count = 0
    end

    def block_method(one, two, &block)
      @calculation_count = @calculation_count + 1
      result = one + two
      if block_given? then
        block.call(result)
      else
        result
      end
    end

    def test_method(one, two)
      @calculation_count = @calculation_count + 1
      one + two
    end
  end

  describe "Memoizing" do
    before :each do
      @memo = Memo.new
    end

    it "should permit normal calling of a method" do
      @memo.call(:+, 1, 2).should == 1 + 2
    end

    it "should memoise the result of a method call" do
      test = MemoTest.new
      2.times { @memo.call(:test_method, test, 1, 2) }
      test.calculation_count.should == 1
    end

    it "should permit passing in a block to a method" do
      test = MemoTest.new
      result = @memo.call(:block_method, test, 1, 2) { |n| n + 3 }
      result.should == 6
    end

    it "should memoise the result of a method call using a reference to a block" do
      block = Proc.new { |n| n + 3}
      test = MemoTest.new
      5.times {
        @memo.call(:block_method, test, 1, 2, &block)
      }

      test.calculation_count.should == 1
    end

    it "should not memoise the result of a method call using a block" do
      # In Ideal Land this would work: treat the block as just another
      # parameter so that repeated invocations of a method with the same
      # arguments + block would memoise. However, each iteration in the
      # loop below creates a whole new block.
      #
      # This spec thus documents actual behaviour, rather than desired
      # behaviour.
      test = MemoTest.new
      n = 5
      n.times {
        @memo.call(:block_method, test, 1, 2) { |n| n + 3 }
      }

      test.calculation_count.should == n
    end

    it "should not memoise messages sent to another object" do
      test1 = MemoTest.new
      test2 = MemoTest.new
      @memo.call(:test_method, test1, 1, 2)
      @memo.call(:test_method, test2, 1, 2)

      test2.calculation_count.should == 1
    end

    it "should not memoise messages sent with different arguments" do
      test = MemoTest.new
      @memo.call(:block_method, test, 1, 2)
      @memo.call(:block_method, test, 1, 2) { |n| n + 3 }
      @memo.call(:block_method, test, 2, 1)

      test.calculation_count.should == 3
    end
  end

  describe "Memoizer module" do
    it "should permit a class to still send normal defined messages" do
      test = ModuleMemoTest.new
      test.test_method(1, 2).should == 3
    end

    it "should not memoise calls unless asked" do
      test = ModuleMemoTest.new
      test.test_method(1, 2).should == 3
      test.calculation_count.should == 1

      test.memo_test_method(1, 2)
      test.calculation_count.should == 2

      test.memo_test_method(1, 2)
      test.calculation_count.should == 2
    end

    it "should recognise memoised message names" do
      test = ModuleMemoTest.new

      test.memo_plainname.should == "plainname"
      test.memo_query?.should == "query?"
      test.memo_underscore_name.should == "underscore_name"
      test.memo_underscore_query?.should == "underscore_query?"
      test.memo_underscore_with_digits_123.should == "underscore_with_digits_123"
      test.memo_underscore_query_with_digits_123?.should == "underscore_query_with_digits_123?"
      test.memo_namewithdigits123.should == "namewithdigits123"
      test.memo_querywithdigits123?.should == "querywithdigits123?"
      test.memo_capitalisedName.should == "capitalisedName"
      test.memo_capitalisedQuery.should == "capitalisedQuery"
    end

    it "should not memoise bang messages" do
      test = ModuleMemoTest.new
      ->{ test.memo_bang_name! }.should raise_error(NoMethodError)
    end

    it "should augment a class to automatically memoise message sends" do
      test = ModuleMemoTest.new
      test.memo_test_method(1, 2)
      test.memo_test_method(1, 2)
      test.calculation_count.should == 1
    end

    class ModuleMemoTest < MemoTest
      include Memoizer

      def plainname
        "plainname"
      end

      def query?
        "query?"
      end

      def underscore_name
        "underscore_name"
      end

      def underscore_query?
        "underscore_query?"
      end

      def underscore_with_digits_123
        "underscore_with_digits_123"
      end

      def underscore_query_with_digits_123?
        "underscore_query_with_digits_123?"
      end

      def namewithdigits123
        "namewithdigits123"
      end

      def querywithdigits123?
        "querywithdigits123?"
      end

      def capitalisedName
        "capitalisedName"
      end

      def capitalisedQuery
        "capitalisedQuery"
      end

      def bang_name!
        "bang_name!"
      end
    end
  end
end
