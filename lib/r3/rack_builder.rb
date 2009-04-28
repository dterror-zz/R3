module R3

# TODO: Gotta add the strategy behind having different implementations for route, mapper and builder
# - gotta check why map.resources isn't working


  class AdapterRoute

    attr_accessor :name, :http_methods, :path_info
    
    def initialize(route)
      @rails_route = route
      @name = []
    end
    
    def http_methods
      @http_methods ||= generate_http_methods_list
    end
    
    def generate_http_methods_list
        if @rails_route.conditions[:method]
          [@rails_route.conditions[:method].to_s.upcase]
        else
          %w(GET POST PUT DELETE HEAD)
        end
    end
    private :generate_http_methods_list
        
    def mount_point?
      false
    end
    
    def path_info
      @path_info ||= Rack::Router::PathCondition.new(:path_info, @rails_route.segments.join(""), @rails_route.conditions, true)
    end
    
    def compile(router)
      @router = router
      @path_info = Rack::Router::PathCondition.new(:path_info, @rails_route.segments.join(""), @rails_route.conditions, true)
      @http_methods = [@rails_route.conditions[:method].to_s.upcase] if @rails_route.conditions[:method]
      @http_methods ||= %w(GET POST PUT DELETE HEAD)
    end
    
    def handle(request, env)
      params = @rails_route.recognize(env['PATH_INFO'], request)
      return unless params
      controller = "#{params[:controller].camelize}Controller".constantize
      controller.call(env).to_a
    end
        
  end 
  
  
  class RackBuilder
    
    # There must be the distinction between what's a rack builder (the responsable to process the dls)
    # and the rails' builder, which's the 'helper' that generates the route objects. In rails'speak
    # the rack-builder would be the mapper. Approximatelly.
    
    attr_accessor :routes, :named_routes
    
    def initialize
      @routes = []
      @named_routes = ActionController::Routing::RouteSet::NamedRouteCollection.new
    end
    
    def self.run(options)
      rack_builder = new
      yield rack_builder.mapper.new(rack_builder)
      rack_builder.routes
    end

    # Here starts the builder interface
    
    def builder
      @builder ||= ActionController::Routing::RouteBuilder.new
    end
    
    def mapper
      @mapper ||= ActionController::Routing::RouteSet::Mapper
    end
    
    def add_route(path, options = {})
      rails_route = builder.build(path, options)
      route = AdapterRoute.new(rails_route)
      routes << route
      route
    end

    def add_named_route(name, path, options = {})
      # TODO - is options EVER used?
      name = options[:name_prefix] + name.to_s if options[:name_prefix]
      named_routes[name.to_sym] = add_route(path, options)
    end
    
  end

end