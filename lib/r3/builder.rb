module R3

  class Builder
    
    OPTIONS = [ :path_prefix, :name_prefix, :namespace, :requirements, :defaults, :conditions ]
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
    
    module MethodHijack
       # let's hope they don't change the method signature
       def map(*args)
          Rack::Router::Builder::Simple.new.method(:map).call(*args)
       end
    end
    ActionController::Routing::RouteSet::Mapper.instance_eval { include(MethodHijack) }
    
         
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
      # path.gsub!(regexp, "(\1)")
      # this is the weirdest detail ever, the $1 interpolation only works with single quoted strings
      # check how 1.9 deals with this
      path.gsub!(regexp, '(\1)')
      path = "#{options[:path_prefix]}/#{path}"

      request_conditions, segment_conditions = {}, {}

      (options[:conditions] || {}).each do |k,v|
        v = v.to_s unless v.is_a?(Regexp)
        REQUEST_METHODS.include?(k.to_s) ?
          request_conditions[k] = v :
          segment_conditions[k] = v
      end
      
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
      route.name = [options[:name_prefix], name].join('_').to_sym
      route
    end
    
  end

end