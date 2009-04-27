require 'rubygems'
require 'rack/test'
require 'test_helper'




class R3Test < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    ActionController::Dispatcher.new
  end
  
  
end
