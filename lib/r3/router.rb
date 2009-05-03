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
    
    def generate(options, recall = {}, method=:generate)
      params, fallback = {}, {}
      named_route_name = options.delete(:use_route)
      if named_route_name
        params[:id] = options.delete(:id).to_param if options[:id] && options[:id].respond_to?(:to_param)
        fallback = options
        url(named_route_name, params, fallback)
      else
        url(options)
      end

      # url(name, options, fallback)
    end
    
    # Refactor this whole thing. It needs strategy.
    def call(env)
       res = routable_call(env)
       if res[1]["X-Rack-Rotuter-Status"] == "404 Not Found" && !env['rack_router.testing']
          raise ActionController::RoutingError, "No routes matched"
       end
       res
    end
    
 end
  
end