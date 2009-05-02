require 'rubygems'
require 'rack/router'
$LOAD_PATH.unshift File.dirname(__FILE__)

module R3
  autoload :Router,                   'r3/router'
  autoload :InitializationInterface,  'r3/initialization_interface'
  autoload :Builder,                  'r3/builder'
end


#  Have to monkey patch this because Rails expects that interfaces when
#  ActionController::Routing::RouteSet::Mapper calls root to make a root
#  route with a symbol parameter (refering to another already defined route)
# it then does some working directly into the route object

class Rack::Router::Route
   
   def defaults
      @params
   end
   
   def conditions
      @request_conditions.merge @segment_conditions
   end
   
end


