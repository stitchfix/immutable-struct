# Immutable Struct

Creates struct-like classes (that can build value objects) that do not have setters and also have better constructors than Ruby's built-in `Struct`.

## Install

Add to your `Gemfile`:

```ruby
gem 'immutable-struct'
```

## To use

See RDoc on `ImmutableStruct` for more details, but basically:


```ruby
Person = StitchFix::ImmutableStruct.new(:name, :age, :active?) do
  def minor?
    age < 18
  end
end

p = Person.new(name: "Dave", age: 40, active: true)
p.name    # => "Dave"
p.age     # => 40
p.active? # => true
p.minor?  # => false
```

Note that we created our class using `:active?`, which tells it that it's a boolean property, but that we can still use `:active` when creating instances.
