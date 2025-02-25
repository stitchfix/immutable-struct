GEM_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..'))
Dir["#{GEM_ROOT}/spec/support/**/*.rb"].sort.each {|f| require f}

require 'immutable-struct'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect]
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  Kernel.srand config.seed

  config.example_status_persistence_file_path = "spec/examples.txt"
end
