require 'r3'

ActionController::Routing::Routes = R3::Router.new


class ActionController::Request
   # make env['rack_router.params'] availlable to ActionController params' hash
   def parameters
     @parameters ||= request_parameters.merge(query_parameters).update(path_parameters).update(env['rack_router.params']).with_indifferent_access
   end
end