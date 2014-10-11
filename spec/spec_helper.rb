require 'rubygems'
require 'readability'
require 'rr'
require 'fakeweb'

FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.mock_with :rr

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
