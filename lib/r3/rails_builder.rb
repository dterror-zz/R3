module R3


  class MockRoute
    def initialize(app)
      @app = app
      @http_methods = []
      @name = ''
    end
    
    attr_accessor :http_methods, :name
    
    def mount_point?
      false
    end
    
    def handle(request, env)
      @app.call(env)
    end
    
    def compile(router)
      []
    end
  end

  class RailsBuilder
    
    OPTIONS = [ :path_prefix, :name_prefix, :namespace, :requirements, :defaults, :conditions ]
    
    class DynamicController
      def self.call(env)
        params     = env["rack_router.params"]
        controller = "#{params[:controller].camelize}Controller".constantize
        controller.call(env).to_a
      end
    end
    
    def self.run(options = {})
      builder = new
      mapper  = ActionController::Routing::RouteSet::Mapper.new(builder)
      yield mapper
      builder.instance_variable_get(:@routes)
    end
    
    def initialize
      @routes = []
    end
    
    def add_route(path, options = {})
      defaults = { :action => 'index', :id => nil }
      defaults.merge! options.reject { |k, v| OPTIONS.include?(k) }
      defaults.merge! options[:defaults] || {}
      
      raise ActionController::RoutingError, ":path cannot have a default" if defaults[:path] && !defaults[:path].empty?
      
      # Find all implicit optional segments and make them explicit
      regexp = defaults.keys.join('|')
      regexp = %r'((?:/|\.):(?:#{regexp}))'
      
      path.gsub!(regexp, "(\1)")

      path = "/#{path}" unless path[0] == ?/
      path = "#{path}/" unless path[-1] == ?/

      prefix = options[:path_prefix].to_s.gsub(/^\//,'')
      path = "/#{prefix}#{path}" unless prefix.blank?

      #route = Rack::Router::Route.new(DynamicController, path, {:path_info => path}, {}, defaults, false)
      route = MockRoute.new(R3::SimpleRackApps::HiApp)
      @routes << route
      route
    end
    
    def add_named_route(name, path, options = {})
      route = add_route(path, options)
      route.name = [options[:name_prefix], name].join('_').to_sym
      route
    end   
  end

end