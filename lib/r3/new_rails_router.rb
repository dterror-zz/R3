module R3

  class NewRailsRouter
  
    include Rack::Router::Routable
 
    def initialize
      self.configuration_files = []
      @routes = []
    end
  
    # def draw(options={}, &block)
    #   options[:builder] = R3::RailsBuilder
    #   prepare(options, &block)
    # end

    # Either rewrite this using prepare or change Routable to have another set-up
    # prefer to rewrite this using prepare then encapsulate mapper into a builder
    def draw
      yield ActionController::Routing::RouteSet::Mapper.new(self)
      # install_helpers
    end
    
    include R3::InitializationInterface
    

    # Here starts the builder interface
    
    def builder
      @builder ||= ActionController::Routing::RouteBuilder.new
    end
    
    def add_route(path, options = {})
      route = builder.build(path, options)
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