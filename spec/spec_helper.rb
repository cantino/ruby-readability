require 'rubygems'
require 'readability'
require 'rr'
require 'fakeweb'

RSpec.configure do |config|
  config.mock_with :rr
end

FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:get, "http://img.thesun.co.uk/multimedia/archive/01416/dim_1416768a.jpg", :body => File.read(File.dirname(__FILE__) + "/fixtures/images/dim_1416768a.jpg"))