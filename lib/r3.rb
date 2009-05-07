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
   
   alias :default_handle :handle
   
   def handle(request, env)
     if path_info.segments.include? :controller
       res = default_handle(request, env)
       return res if res.is_a?(Array) && res[1]["X-Rack-Router-Status"] != "404 Not Found"
       # this weird hack is to support rails style of being smart about segments. It conflits with rack_router's
       # path_info matching mechanism that separates everything between a '/' to be a segment, which makes supporting
       # namespaced controllers (admin/posts) very hard on default routes. DEFAUT ROUTES ARE EVIL
       
       # rewrite this route
       path_info.segments.insert(path_info.segments.index(:controller), :namespace, "/")
       old_path_info_condition = @request_conditions[:path_info]
       new_path_info_condition = Rack::Router::Condition.new(:path_info, path_info.segments, segment_conditions, false)
       @request_conditions[:path_info] = new_path_info_condition
       # and call it again
       second_try = default_handle(request, env)
       # rewrite the route back +__+
       path_info.segments.delete_at(path_info.segments.index(:namespace)+1)
       path_info.segments.delete(:namespace)
       @request_conditions[:path_info] = old_path_info_condition
       return second_try
       # Thank god this doesn't happen very often. Only in the bloody rails/info/properties
     else
       default_handle(request, env)
     end
   end
   
end


