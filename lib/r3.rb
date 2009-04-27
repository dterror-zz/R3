require 'rubygems'
require 'rack/router'

module R3
  autoload :NewRailsRouter,           'r3/new_rails_router'
  autoload :SimpleRackApps,           'r3/simple_rack_apps'
  autoload :InitializationInterface,  'r3/initialization_interface'
  autoload :RailsBuilder,             'r3/rails_builder'
end

# module Rack::Router::Routable
#   def call(env)
#     # env["rack_router.params"] ||= {}
#     # 
#     # route_set = @route_sets[env["REQUEST_METHOD"]]
#     # env["PATH_INFO"].scan(/#{SEGMENT_CHARACTERS}+/) do |s|
#     #   route_set = route_set[s]
#     # end
#     # route_set.handle(Rack::Request.new(env), env)
#     @routes.each do |route|
#       route.handle("",{})
#     end
#   end
# end










