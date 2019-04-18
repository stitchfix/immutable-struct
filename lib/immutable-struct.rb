# Creates classes for value objects/read-only records.  Most useful
# when creating model objects for concepts not stored in the database.
#
# This will create a class that has attr_readers for all given attributes, as
# well as a hash-based constructor.  Further, the block given to with_attributes
# will be evaluated as if it were inside a class definition, allowing you
# to add methods, include or extend modules, or do whatever else you want.
class ImmutableStruct
  VERSION='2.4.1' #:nodoc:
  # Create a new class with the given read-only attributes.
  #
  # attributes:: list of symbols or strings that can be used to create attributes.
  #              Any attribute with a question mark in it (e.g. +:foo?+) will create
  #              an attribute without a question mark that passes through the raw
  #              value and an attribute *with* the question mark that coerces that
  #              value to a boolean.  You would initialize it with the non-question-mark value
  #              An attribute that is an array of one symbol will create an attribute named for
  #              that symbol, but that doesn't return nil, instead returning the +to_a+ of the
  #              value passed to the construtor.
  # block:: if present, evaluates in the context of the new class, so +def+, +def.self+, +include+
  #         and +extend+ should all work as in a normal class definition.
  #
  # Example:
  #
  #     Person = ImmutableStruct.new(:name, :location, :minor?, [:aliases])
  #
  #     p = Person.new(name: 'Dave', location: Location.new("DC"), minor: false)
  #     p.name     # => 'Dave'
  #     p.location # => <Location: @where="DC">
  #     p.minor    # => false
  #     p.minor?   # => false
  #
  #     p = Person.new(name: 'Rudy', minor: "yup")
  #     p.name     # => 'Rudy'
  #     p.location # => nil
  #     p.minor    # => "yup"
  #     p.minor?   # => true
  #
  #     new_person = p.merge(name: "Other Dave", age: 41) # returns a new object with merged attributes
  #     new_person.name    # => "Other Dave"
  #     new_person.age     # => 41
  #     new_person.active? # => true
  #
  # Note that you also get an implementation of `to_h` that will include **all** no-arg methods in its
  # output:
  #
  #     Person = ImmutableStruct.new(:name, :location, :minor?, [:aliases])
  #     p = Person.new(name: 'Dave', minor: "yup", aliases: [ "davetron", "davetron5000" ])
  #     p.to_h # => { name: "Dave", minor: "yup", minor?: true, aliases: ["davetron", "davetron5000" ] }
  #
  # This has two subtle side-effects:
  #
  # * Methods that take no args, but are not 'attributes' will get called by `to_h`.  This shouldn't be a
  #   problem, because you should not generally be doing this on a struct-like class.
  # * Methods that take no args, but call `to_h` will stack overflow.  This is because the class'
  #   internals have no way to know about this.  This is particularly a problem if you want to
  #   define your own `to_json` method that serializes the result of `to_h`.
  #
  def self.new(*attributes,&block)
    klass = Class.new do
      attributes.each do |attribute|
        if attribute.to_s =~ /(^.*)\?$/
          raw_name = $1
          attr_reader raw_name
          define_method(attribute) do
            !!instance_variable_get("@#{raw_name}")
          end
        elsif attribute.kind_of?(Array) and attribute.size == 1
          attr_reader attribute[0]
        else
          attr_reader attribute
        end
      end

      def self.from(value)
        case value
        when self then value
        when Hash then new(value)
        else
          raise ArgumentError, "cannot coerce #{value.class} #{value.inspect} into #{self}"
        end
      end

      define_method(:initialize) do |*args|
        attrs = args[0] || {}
        attributes.each do |attribute|
          if attribute.kind_of?(Array) and attribute.size == 1
            ivar_name = attribute[0].to_s
            instance_variable_set("@#{ivar_name}", (attrs[ivar_name.to_s] || attrs[ivar_name.to_sym]).to_a)
          else
            ivar_name = attribute.to_s.gsub(/\?$/,'')
            attr_value = attrs[ivar_name.to_s].nil? ? attrs[ivar_name.to_sym] : attrs[ivar_name.to_s]
            instance_variable_set("@#{ivar_name}", attr_value)
          end
        end
      end

      define_method(:==) do |other|
        return false unless other.is_a?(klass)
        attributes.all? do |attribute|
          if attribute.kind_of?(Array) and attribute.size == 1
            attribute = attribute[0].to_s
          end
          self.send(attribute) == other.send(attribute)
        end
      end

      def merge(new_attrs)
        attrs = to_h
        self.class.new(attrs.merge(new_attrs))
      end

      alias_method :eql?, :==

      define_method(:hash) do
        attribute_values = attributes.map do |attribute|
          if attribute.kind_of?(Array) and attribute.size == 1
            attribute = attribute[0].to_s
          end
          self.send(attribute)
        end
        (attribute_values + [self.class]).hash
      end
    end
    klass.class_exec(&block) unless block.nil?

    imethods = klass.instance_methods(include_super=false).map { |method_name|
      klass.instance_method(method_name)
    }.reject { |method|
      method.arity != 0
    }.map(&:name).map(&:to_sym)

    klass.class_exec(imethods) do |imethods|
      define_method(:to_h) do
        imethods.inject({}) do |hash, method|
          next hash if [:==, :eql?, :merge, :hash].include?(method)
          hash.merge(method.to_sym => self.send(method))
        end
      end
      alias_method :to_hash, :to_h
    end
    klass
  end
end
