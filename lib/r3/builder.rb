module R3

  class Builder
     
     autoload :DynamicController,   'r3/builder/dynamic_controller'
     autoload :NamedRoutes,         'r3/builder/named_routes'
     
     # Load the required rails additions (monkey patches)
     load('r3/builder/rails_ext.rb')
    
     OPTIONS = [ :path_prefix, :name_prefix, :namespace, :requirements, :defaults, :conditions, :request_method ]
     REQUEST_METHODS = Rack::Request.instance_methods - Object.instance_methods
     DEFAULT_PARAMS = { :action => 'index', :id => nil, :format => 'html' }
         
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
    
    # This should only be used by ActionController::Routing::RouteSet::Mapper#map 
    def add_route_directly(route)
      raise "Expected Route Object, but got #{route.class}" unless route.is_a? Rack::Router::Route
      @routes << route
      route
    end

    def add_route(path, options = {})
      # Special case as rails doesn't pass it in the requirement hash
      if options[:id] && options[:id].is_a?(Regexp)
        options[:requirements] ||= {}
        options[:requirements].merge!({:id => options[:id]})
      end

      default_params = process_defaults(options)

      # Find all implicit optional segments and make them explicit
      path = reveal_implicit_segments(path, default_params.keys)
      path = "#{options[:path_prefix]}/#{path}" if options[:path_prefix]


      request_conditions, segment_conditions = process_match_conditions( path,
                                                       (options[:conditions] || {}),
                                                       (options[:requirements] || {})
                                                    )
                                              
      route = Rack::Router::Route.new(DynamicController,
                                                    path,
                                                    request_conditions,
                                                    segment_conditions,
                                                    default_params,
                                                    false )
                                        
      if options[:name]
        route.name = options[:name_prefix] ? 
                      [options[:name_prefix], options[:name]].join('_').to_sym :
                      options[:name].to_sym
        @named_routes << route
      end

      @routes << route
      route        
    end
    
    def add_named_route(name, path, options = {})
       options[:name] = name
       add_route(path, options)
    end
    
    
    private
        
    def process_defaults(options)
       defaults = DEFAULT_PARAMS.dup
       defaults.merge!(options.reject do |k, v|
            OPTIONS.include?(k) || [:options, :requirements, :conditions, :defaults, :name].include?(k)
          end)
       defaults.merge! options[:defaults] || {}
       
       if defaults[:path] && !defaults[:path].empty?
          raise ActionController::RoutingError, ":path cannot have a default"
       end
       
       defaults
    end
    
    def process_match_conditions(path, conditions, requirements)
       request_conditions, segment_conditions = {}, {}
       match_conditions = conditions.merge requirements

       if match_conditions[:method]
          match_conditions[:request_method] = upcase_method(match_conditions.delete(:method)) 
       end

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

       return request_conditions, segment_conditions
    end
     
    def reveal_implicit_segments(path, params)
       regexp = params.join('|')
       regexp = %r'((?:/|\.):(?:#{regexp}))'
       path.gsub(regexp, '(\1)')
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
    
  end

end