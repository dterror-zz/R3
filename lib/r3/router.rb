module R3

  class Router
    
    include Rack::Router::Routable
    include R3::InitializationInterface

    alias :routable_call :call
    
    def initialize
       self.configuration_files = []
       @routes = []
    end
  
    def draw(options={}, &block)
       options[:builder] = R3::Builder
       prepare(options, &block)
       install_helpers
       self
    end
    
    # I'm afraid I'll have to keep it here for now
    def prepare(options = {}, &block)
      builder       = options.delete(:builder) || Rack::Router::Builder::Simple
      @dependencies = options.delete(:dependencies) || {}
      @root         = self
      @named_routes = ActionController::Routing::RouteSet::NamedRouteCollection.new
      @mounted_apps = {}
      @routes       = []
 
      builder.run(options, &block).each do |route|
        prepare_route(route)
      end
 
      finalize
 
      # Set the root of the router tree for each router
      descendants.each { |d| d.root = self }
 
      self
    end
    
    def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
      Array(destinations).each { |d| d.module_eval { include ActionController::Routing::Helpers } }
      named_routes.install(destinations, regenerate_code)
    end
    
    def options_to_params!(options)
      objects_ids = {}
      options.each do |k,v|
        objects_ids[k] = options.delete(k).to_param if v.respond_to?(:to_param)
      end
      objects_ids
    end
    
    def generate(options, recall = {}, method=:generate)
      params, fallback = {}, {}
      named_route_name = options.delete(:use_route)
      if named_route_name
        params.update(options_to_params!(options)).reject! {|k,v|  [:controller, :action, :format].include?(k) }
        fallback = options
        url(named_route_name, params, fallback)
      else
        #nil
      end
    end
    
    # Refactor this whole thing. It needs strategy.
    # It's using an alias to the original rack-router/routable call method
    def call(env)
       res = routable_call(env)
       if res[1]["X-Rack-Rotuter-Status"] == "404 Not Found" && !env['rack_router.testing']
          raise ActionController::RoutingError, "No routes matched"
       end
       res
    end
    
 end
  
end