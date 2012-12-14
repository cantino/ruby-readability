require 'rubygems'
require 'readability'
require 'rr'
require 'fakeweb'

FakeWeb.allow_net_connect = true

RSpec.configure do |config|
  config.mock_with :rr
end

