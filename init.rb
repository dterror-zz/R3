require 'r3'

ActionController::Routing::Routes = R3::Router.new



class ActionController::Request
  
  def path_parameters
    (@env['rack_router.params'] || {}).reject {|k,v| k == :format }
  end

end