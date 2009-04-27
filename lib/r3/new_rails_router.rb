module R3

  class NewRailsRouter
  
    include Rack::Router::Routable
 
    def initialize
      self.configuration_files = []
      @routes = []
      @mapper = ActionController::Routing::RouteSet::Mapper
    end
  
    # def draw(options={}, &block)
    #   prepare(options, &block)
    # end

    def draw
      yield @mapper.new(self)
    end
    
    include R3::MapperInterface
    include R3::InitializationInterface
  end
  
end