require 'rubygems'
require 'rack/router'
$LOAD_PATH.unshift File.dirname(__FILE__)

module R3
  autoload :Router,                   'r3/router'
  autoload :InitializationInterface,  'r3/initialization_interface'
  autoload :Builder,                  'r3/builder'
end




class Rack::Router::Route
  #  Have to monkey patch this because Rails expects that interfaces when
  #  ActionController::Routing::RouteSet::Mapper calls root to make a root
  #  route with a symbol parameter (refering to another already defined route)
  # it then does some working directly into the route object
     
   def defaults
      @params
   end
   
   def conditions
      @request_conditions.merge @segment_conditions
   end
   
   # Because ActionController::Routin::RouteSet::NamedRouteCollection calls them
   def optimise?
     false
   end
   
   def segment_keys
     path_info.captures
   end
   
end


