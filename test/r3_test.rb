require 'rubygems'
require 'rack/test'
require 'test_helper'

class R3Test < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    ActionController::Dispatcher.new
  end
  
  def test_nothing
    get '/hi'
    assert last_response.ok?
  end
  
  
end
