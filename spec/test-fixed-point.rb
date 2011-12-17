require 'rdev/fixed-point'

module DerParser
  describe "'Dynamic variables'" do
    it "should permit inspection of value" do
      DynVar.new({:foo => 1}).foo.should == 1
    end

    it "should pass unknown method calls to the usual handler" do
      lambda {
        DynVar.new({:foo => 1}).bar
      }.should raise_error NoMethodError
    end

    it "should allow binding of multiple values" do
      dv = DynVar.new({:foo => 1, :bar => 2})
      dv.foo.should == 1
      dv.bar.should == 2
    end

    it "should allow binding of query-like names" do
      DynVar.new({:foo? => 1}).foo?.should == 1
    end

    it "should allow rebinding of known values" do
      dv = DynVar.new({:foo => 1})
      dv.rebind_foo(2)
      dv.foo.should == 2
    end

    it "should allow binding of query-like names" do
      dv = DynVar.new({:foo? => 1})
      dv.rebind_foo?(2)
      dv.foo?.should == 2
    end

    it "should allow unbinding of names" do
      dv = DynVar.new({:foo => 1})
      dv.rebind_foo(2)
      dv.unbind_foo
      dv.foo.should == 1
    end

    it "should allow unbinding of query-like names" do
      dv = DynVar.new({:foo? => 1})
      dv.rebind_foo?(2)
      dv.unbind_foo?
      dv.foo?.should == 1
    end

    it "should allow scoped rebinding" do
      dv = DynVar.new({:foo => 1})
      inner_val = :declared_for_correct_scoping
      innermost_val = :declared_for_correct_scoping
      dv.rebind_foo(2) {
        inner_val = dv.foo
        dv.rebind_foo(3) {
          innermost_val = dv.foo
        }
      }
      dv.foo.should == 1
      inner_val.should == 2
      innermost_val.should == 3
    end
  end

  describe LeastFixedPoint do
  end
end
