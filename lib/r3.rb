require 'rubygems'
require 'rack/router'

module R3
  autoload :Router,                   'r3/router'
  autoload :InitializationInterface,  'r3/initialization_interface'
  autoload :Builder,                  'r3/builder'
  autoload :SimpleRackApps,           'r3/simple_rack_apps'
end


# module Rack::Router::Routable
#   def call(env)
#     
#     env["rack_router.params"] ||= {}
#   
#     route_set = @route_sets[env["REQUEST_METHOD"]]
#     
#     puts "Routeset for method: #{route_set.inspect}"
#   
#     local_segment_characters = "[^\/.,;?]"
#     env["PATH_INFO"].scan(/#{local_segment_characters}+/) do |s|
#       puts "Segments in PATH_INFO are: #{s}"
#       route_set = route_set[s]
#     end
#     puts "New RouteSet is #{route_set} of class #{route_set.class}"
#     
#     route_set.handle(Rack::Request.new(env), env)
#   end
# end







