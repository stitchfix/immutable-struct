require 'spec_helper.rb'

module TestModule
  def hello; "hello"; end
end

describe ImmutableStruct do
  describe "construction" do
    context "with non-boolean attributes and no body" do
      before do
        @klass = ImmutableStruct.new(:foo, :bar, :baz)
      end
      subject { @klass.new }

      it { should     respond_to(:foo) }
      it { should     respond_to(:bar) }
      it { should     respond_to(:baz) }
      it { should_not respond_to(:foo=) }
      it { should_not respond_to(:bar=) }
      it { should_not respond_to(:baz=) }
      it { should_not respond_to(:foo?) }
      it { should_not respond_to(:bar?) }
      it { should_not respond_to(:baz?) }

      context "instances can be created with a hash" do

        context 'with symbol keys' do
          subject { @klass.new(foo: "FOO", bar: 42, baz: [:a,:b,:c]) }

          it { subject.foo.should == "FOO" }
          it { subject.bar.should == 42 }
          it { subject.baz.should == [:a,:b,:c] }
        end

        context "with string keys" do
          subject { ImmutableStruct.new(:foo) }

          it { subject.new('foo' => true).foo.should == true }
          it { subject.new('foo' => false).foo.should == false }
        end
      end
    end

    context "intelligently handles boolean attributes" do
      subject { ImmutableStruct.new(:foo?) }

      context "with boolean values" do
        it { subject.new(foo: false).foo?.should == false }
        it { subject.new(foo: false).foo.should == false }
        it { subject.new(foo: true).foo?.should == true }
        it { subject.new(foo: true).foo.should == true }
      end

      context "with falsey, non-boolean values" do
        it { subject.new.foo?.should == false }
        it { subject.new.foo.should == nil }
      end

      context "with truthy, non-boolean values" do
        it { subject.new(foo: "true").foo?.should == true }
        it { subject.new(foo: "true").foo.should == "true" }
      end
    end

    context "allows for values that should be coerced to collections" do
      it "can define an array value that should never be nil" do
        klass = ImmutableStruct.new([:foo], :bar)
        instance = klass.new
        instance.foo.should == []
        instance.bar.should == nil
      end
    end

    it "allows defining instance methods" do
      klass = ImmutableStruct.new(:foo, :bar) do
        def derived; self.foo + ":" + self.bar; end
      end
      instance = klass.new(foo: "hello", bar: "world")
      instance.derived.should == "hello:world"
    end

    it "allows defining class methods" do
      klass = ImmutableStruct.new(:foo, :bar) do
        def self.from_array(array)
          new(foo: array[0], bar: array[1])
        end
      end
      instance = klass.from_array(["hello","world"])
      instance.foo.should == "hello"
      instance.bar.should == "world"
    end

    it "allows module inclusion" do
      klass = ImmutableStruct.new(:foo) do
        include TestModule
      end
      instance = klass.new

      instance.should  respond_to(:hello)
      klass.should_not respond_to(:hello)
    end

    it "allows module extension" do
      klass = ImmutableStruct.new(:foo) do
        extend TestModule
      end
      instance = klass.new

      instance.should_not respond_to(:hello)
      klass.should        respond_to(:hello)
    end
  end

  describe "to_h" do
    it "should include the output of params and block methods in the hash" do
      klass = ImmutableStruct.new(:name, :minor?, :location, [:aliases]) do
        def nick_name
          'bob'
        end
      end
      instance = klass.new(name: "Rudy", minor: "ayup", aliases: [ "Rudyard", "Roozoola" ])
      instance.to_h.should == {
        name: "Rudy",
        minor: "ayup",
        minor?: true,
        location: nil,
        aliases: [ "Rudyard", "Roozoola"],
        nick_name: "bob",
      }
    end
  end

  describe "merge" do
    it "returns a new object as a result of merging attributes" do
      klass = ImmutableStruct.new(:food, :snacks, :butter)
      instance = klass.new(food: 'hot dogs', butter: true)
      new_instance = instance.merge(snacks: 'candy hot dogs', butter: false)

      instance.food.should == 'hot dogs'
      instance.butter.should == true
      instance.snacks.should == nil

      new_instance.food.should == 'hot dogs'
      new_instance.snacks.should == 'candy hot dogs'
      new_instance.butter.should == false

      new_instance.object_id.should_not == instance.object_id
    end
  end

  describe "equality" do

    before do
      klass_1 = ImmutableStruct.new(:foo, :bar)
      klass_2 = ImmutableStruct.new(:foo, :bar)
      @k1_a = klass_1.new(foo: 'foo', bar: 'bar')
      @k1_b = klass_1.new(foo: 'xxx', bar: 'yyy')
      @k1_c = klass_1.new(foo: 'foo', bar: 'bar')
      @k2_a = klass_2.new(foo: 'foo', bar: 'bar')
    end

    describe "==" do

      it "should be equal to itself" do
        (@k1_a == @k1_a).should be true
      end

      it "should be equal to same class with identical attribute values" do
        (@k1_a == @k1_c).should be true
      end

      it 'should not be equal to same class with different attribute values' do
        (@k1_a == @k1_b).should be false
      end

      it 'should not be equal to different class with identical attribute values' do
        (@k1_a == @k3_a).should be false
      end

    end

    describe "eql?" do

      it "should be equal to itself" do
        @k1_a.eql?(@k1_a).should be true
      end

      it "should be equal to same class with identical attribute values" do
        @k1_a.eql?(@k1_c).should be true
      end

      it 'should not be equal to same class with different attribute values' do
        @k1_a.eql?(@k1_b).should be false
      end

      it 'should not be equal to different class with identical attribute values' do
        @k1_a.eql?(@k3_a).should be false
      end

    end

    describe "hash" do

      it "should have same hash value as itself" do
        @k1_a.hash.eql?(@k1_a.hash).should be true
      end

      it "should have same hash value as same class with identical attribute values" do
        @k1_a.hash.eql?(@k1_c.hash).should be true
      end

      it 'should not have hash value as same class with different attribute values' do
        @k1_a.hash.eql?(@k1_b.hash).should be false
      end

      it 'should not have hash value equal to different class with identical attribute values' do
        @k1_a.hash.eql?(@k3_a.hash).should be false
      end

      it 'should reject set addition if same instance is already a member' do
        set = Set.new([@k1_a])
        set.add?(@k1_a).should be nil
      end

      it 'should reject set addition if different instance, but attributes are the same' do
        set = Set.new([@k1_a])
        set.add?(@k1_c).should be nil
      end

      it 'should allow set addition if different instance and attribute values' do
        set = Set.new([@k1_a])
        set.add?(@k1_b).should_not be nil
      end

      it 'should allow set addition if different class' do
        set = Set.new([@k1_a])
        set.add?(@k2_a).should_not be nil
      end

    end

  end
end
