GEM_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..'))
Dir["#{GEM_ROOT}/spec/support/**/*.rb"].sort.each {|f| require f}

require 'immutable-struct'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect]
  end
  config.order = "random"
end
