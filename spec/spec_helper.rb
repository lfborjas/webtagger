$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'webtagger'
require 'fakeweb'
file_opener = lambda {|service| File.open("#{File.dirname(__FILE__)}/fixtures/#{service}.json").read}

FakeWeb.register_uri(:post, "http://tagthe.net/api", :body=>file_opener.call("tagthe"))
FakeWeb.register_uri(:post, "http://access.alchemyapi.com/calls/text/TextGetRankedKeywords",
                     :body=>file_opener.call("alchemy"))

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end
