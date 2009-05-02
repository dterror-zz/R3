module R3

  class Builder
    
    OPTIONS = [ :path_prefix, :name_prefix, :namespace, :requirements, :defaults, :conditions, :request_method ]
    REQUEST_METHODS = Rack::Request.instance_methods - Object.instance_methods

    
    
    class DynamicController
      def self.call(env)
        begin
          params     = env["rack_router.params"]          
          controller = "#{params[:controller].camelize}Controller".constantize
          controller.call(env).to_a
        rescue NameError => e
           Rack::Router::NOT_FOUND_RESPONSE #throwing a more 'readable' error up the stack
        end
      end
    end
    
    # Adding support to rack-router's builder/simple dsl
    class ActionController::Routing::RouteSet::Mapper
       def map(*args)
          route = Rack::Router::Builder::Simple.new.map(*args).pop
          @set.add_route_directly(route)
       end
    end
    
    # Currently I only need this to fool Rails' mapper
    class NamedRoutes
       attr_accessor :routes
       
       def initialize
         @routes = {}
       end
       
       def <<(route)
          @routes[route.name] = route
       end
    end
         
    def self.run(options = {})
      builder = new
      mapper  = ActionController::Routing::RouteSet::Mapper.new(builder)
      yield mapper
      builder.instance_variable_get(:@routes)
    end
    
    attr_reader :named_routes
    def initialize
      @routes = []
      @named_routes = NamedRoutes.new
    end
    
    # That should only be used by ActionController::Routing::RouteSet::Mapper#map 
    def add_route_directly(route)
      raise "Expected Route Object, but got #{route.class}" unless route.is_a? Rack::Router::Route
      @routes << route
      route
    end

    # THIS NEEDS SOME SERIOUS REFACTOTING
    # DO YOU HEAR ME?!
    def add_route(path, options = {})
      defaults = { :action => 'index', :id => nil }
      defaults.merge! options.reject { |k, v| OPTIONS.include?(k) }
      defaults.merge! options[:defaults] || {}
      
      raise ActionController::RoutingError, ":path cannot have a default" if defaults[:path] && !defaults[:path].empty?
      
      # Find all implicit optional segments and make them explicit
      regexp = defaults.keys.join('|')
      regexp = %r'((?:/|\.):(?:#{regexp}))'
      path.gsub!(regexp, '(\1)')
      path = "#{options[:path_prefix]}/#{path}"
      
      request_conditions, segment_conditions = {}, {}

      match_conditions = (options[:conditions] || {}).merge(options[:requirements] || {})
      match_conditions[:request_method] = upcase_method(match_conditions.delete(:method)) if match_conditions[:method]
      match_conditions.each do |k,v|
        v = v.to_s unless v.is_a?(Regexp)
        REQUEST_METHODS.include?(k.to_s) ?
          request_conditions[k] = v :
          segment_conditions[k] = v
      end
      
      # can't constraint action or controller segments, they're bound to code availability
      segment_conditions.delete(:action)
      segment_conditions.delete(:controller)

      request_conditions[:path_info] = Rack::Router::Parsing.parse(path) do |segment_name, delimiter|
        segment_conditions[segment_name] = /.+/ if delimiter == '*'
      end
      
      route = Rack::Router::Route.new(DynamicController, path, request_conditions, segment_conditions, defaults, false)
      route.name = options[:name].to_sym if options[:name]
      @routes << route
      route        
    end
    
    def add_named_route(name, path, options = {})
      route = add_route(path, options)
      route.name = options[:name_prefix] ?
                     [options[:name_prefix], name].join('_').to_sym :
                     name.to_sym
                     
      @named_routes << route
      route
    end
    
    def upcase_method(method)
      case method
      when String, Symbol then method.to_s.upcase
      when Array          then method.map { |m| upcase_method(m) }
      when NilClass       then "GET"
      when Regexp         then method
      else
        raise ArgumentError, "The method #{method.inspect} could not be coerced into a HTTP method"
      end
    end
    private :upcase_method
    
  end

end