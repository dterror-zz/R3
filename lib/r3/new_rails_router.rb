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

    def draw(options={}, &block)
      options[:builder] = R3::RackBuilder
      prepare(options, &block)
      # yield ActionController::Routing::RouteSet::Mapper.new(self)
      # install_helpers
    end
    
    include R3::InitializationInterface
    
  end
  
end