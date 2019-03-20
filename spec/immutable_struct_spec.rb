require 'spec_helper.rb'
require 'json'

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

      it { is_expected.to     respond_to(:foo) }
      it { is_expected.to     respond_to(:bar) }
      it { is_expected.to     respond_to(:baz) }
      it { is_expected.not_to respond_to(:foo=) }
      it { is_expected.not_to respond_to(:bar=) }
      it { is_expected.not_to respond_to(:baz=) }
      it { is_expected.not_to respond_to(:foo?) }
      it { is_expected.not_to respond_to(:bar?) }
      it { is_expected.not_to respond_to(:baz?) }

      context "instances can be created with a hash" do
        context 'with symbol keys' do
          subject { @klass.new(foo: "FOO", bar: 42, baz: [:a,:b,:c]) }

          it { expect(subject.foo).to eq("FOO") }
          it { expect(subject.bar).to eq(42) }
          it { expect(subject.baz).to eq([:a,:b,:c]) }
        end

        context "with string keys" do
          subject { ImmutableStruct.new(:foo) }

          it { expect(subject.new('foo' => true).foo).to eq(true) }
          it { expect(subject.new('foo' => false).foo).to eq(false) }
        end
      end
    end

    context "intelligently handles boolean attributes" do
      subject { ImmutableStruct.new(:foo?) }

      context "with boolean values" do
        it { expect(subject.new(foo: false).foo?).to eq(false) }
        it { expect(subject.new(foo: false).foo).to eq(false) }
        it { expect(subject.new(foo: true).foo?).to eq(true) }
        it { expect(subject.new(foo: true).foo).to eq(true) }
      end

      context "with falsey, non-boolean values" do
        it { expect(subject.new.foo?).to eq(false) }
        it { expect(subject.new.foo).to eq(nil) }
      end

      context "with truthy, non-boolean values" do
        it { expect(subject.new(foo: "true").foo?).to eq(true) }
        it { expect(subject.new(foo: "true").foo).to eq("true") }
      end
    end

    context "allows for values that should be coerced to collections" do
      it "can define an array value that should never be nil" do
        klass = ImmutableStruct.new([:foo], :bar)
        instance = klass.new
        expect(instance.foo).to eq([])
        expect(instance.bar).to eq(nil)
      end
    end

    it "allows defining instance methods" do
      klass = ImmutableStruct.new(:foo, :bar) do
        def derived; self.foo + ":" + self.bar; end
      end
      instance = klass.new(foo: "hello", bar: "world")
      expect(instance.derived).to eq("hello:world")
    end

    it "allows defining class methods" do
      klass = ImmutableStruct.new(:foo, :bar) do
        def self.from_array(array)
          new(foo: array[0], bar: array[1])
        end
      end
      instance = klass.from_array(["hello","world"])
      expect(instance.foo).to eq("hello")
      expect(instance.bar).to eq("world")
    end

    it "allows module inclusion" do
      klass = ImmutableStruct.new(:foo) do
        include TestModule
      end
      instance = klass.new

      expect(instance).to  respond_to(:hello)
      expect(klass).not_to respond_to(:hello)
    end

    it "allows module extension" do
      klass = ImmutableStruct.new(:foo) do
        extend TestModule
      end
      instance = klass.new

      expect(instance).not_to respond_to(:hello)
      expect(klass).to        respond_to(:hello)
    end
  end

  describe "coercion" do
    let(:klass) { ImmutableStruct.new(:lolwat) }

    it "is a noop when value is already the defined type" do
      value = klass.new
      new_value = klass.from(value)
      expect(new_value).to be(value)
    end

    it "initializes a new value when Hash is given" do
      value = klass.from(lolwat: "haha")
      expect(value.lolwat).to eq("haha")
    end

    it "errors when value cannot be coerced" do
      expect { klass.from(Object.new) }
        .to raise_error(ArgumentError)
    end
  end

  describe "to_h" do
    context "vanilla struct with just derived values" do
      it "should include the output of params and block methods in the hash" do
        klass = ImmutableStruct.new(:name, :minor?, :location, [:aliases]) do
          def nick_name
            'bob'
          end
        end
        instance = klass.new(name: "Rudy", minor: "ayup", aliases: [ "Rudyard", "Roozoola" ])
        expect(instance.to_h).to eq({
          name: "Rudy",
          minor: "ayup",
          minor?: true,
          location: nil,
          aliases: [ "Rudyard", "Roozoola"],
          nick_name: "bob",
        })
      end
    end

    context "additional method that takes arguments" do
      it "should not call the additional method" do
        klass = ImmutableStruct.new(:name, :minor?, :location, [:aliases]) do
          def nick_name
            'bob'
          end
          def location_near?(other_location)
            false
          end
        end
        instance = klass.new(name: "Rudy", minor: "ayup", aliases: [ "Rudyard", "Roozoola" ])
        expect(instance.to_h).to eq({
          name: "Rudy",
          minor: "ayup",
          minor?: true,
          location: nil,
          aliases: [ "Rudyard", "Roozoola"],
          nick_name: "bob",
        })
      end
    end

    context "to_hash is its alias" do
      it "is identical" do
        klass = ImmutableStruct.new(:name, :minor?, :location, [:aliases]) do
          def nick_name
            'bob'
          end
          def location_near?(other_location)
            false
          end
        end
        instance = klass.new(name: "Rudy", minor: "ayup", aliases: [ "Rudyard", "Roozoola" ])
        expect(instance.to_h).to eq(instance.to_hash)
      end
    end
  end

  describe "merge" do
    it "returns a new object as a result of merging attributes" do
      klass = ImmutableStruct.new(:food, :snacks, :butter)
      instance = klass.new(food: 'hot dogs', butter: true)
      new_instance = instance.merge(snacks: 'candy hot dogs', butter: false)

      expect(instance.food).to eq('hot dogs')
      expect(instance.butter).to eq(true)
      expect(instance.snacks).to eq(nil)

      expect(new_instance.food).to eq('hot dogs')
      expect(new_instance.snacks).to eq('candy hot dogs')
      expect(new_instance.butter).to eq(false)

      expect(new_instance.object_id).not_to eq(instance.object_id)
    end
  end

  describe "equality" do
    before do
      klass_1 = ImmutableStruct.new(:foo, [:bars])
      klass_2 = ImmutableStruct.new(:foo, [:bars])
      @k1_a = klass_1.new(foo: 'foo', bars: ['bar', 'baz'])
      @k1_b = klass_1.new(foo: 'xxx', bars: ['yyy'])
      @k1_c = klass_1.new(foo: 'foo', bars: ['bar', 'baz'])
      @k2_a = klass_2.new(foo: 'foo', bars: ['bar'])
    end

    describe "==" do
      it "should be equal to itself" do
        expect(@k1_a == @k1_a).to be true
      end

      it "should be equal to same class with identical attribute values" do
        expect(@k1_a == @k1_c).to be true
      end

      it 'should not be equal to same class with different attribute values' do
        expect(@k1_a == @k1_b).to be false
      end

      it 'should not be equal to different class with identical attribute values' do
        expect(@k1_a == @k3_a).to be false
      end
    end

    describe "eql?" do
      it "should be equal to itself" do
        expect(@k1_a.eql?(@k1_a)).to be true
      end

      it "should be equal to same class with identical attribute values" do
        expect(@k1_a.eql?(@k1_c)).to be true
      end

      it 'should not be equal to same class with different attribute values' do
        expect(@k1_a.eql?(@k1_b)).to be false
      end

      it 'should not be equal to different class with identical attribute values' do
        expect(@k1_a.eql?(@k3_a)).to be false
      end
    end

    describe "hash" do
      it "should have same hash value as itself" do
        expect(@k1_a.hash.eql?(@k1_a.hash)).to be true
      end

      it "should have same hash value as same class with identical attribute values" do
        expect(@k1_a.hash.eql?(@k1_c.hash)).to be true
      end

      it 'should not have hash value as same class with different attribute values' do
        expect(@k1_a.hash.eql?(@k1_b.hash)).to be false
      end

      it 'should not have hash value equal to different class with identical attribute values' do
        expect(@k1_a.hash.eql?(@k3_a.hash)).to be false
      end

      it 'should reject set addition if same instance is already a member' do
        set = Set.new([@k1_a])
        expect(set.add?(@k1_a)).to be nil
      end

      it 'should reject set addition if different instance, but attributes are the same' do
        set = Set.new([@k1_a])
        expect(set.add?(@k1_c)).to be nil
      end

      it 'should allow set addition if different instance and attribute values' do
        set = Set.new([@k1_a])
        expect(set.add?(@k1_b)).not_to be nil
      end

      it 'should allow set addition if different class' do
        set = Set.new([@k1_a])
        expect(set.add?(@k2_a)).not_to be nil
      end
    end
  end
end
