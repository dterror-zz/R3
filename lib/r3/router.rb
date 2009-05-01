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