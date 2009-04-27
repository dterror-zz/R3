module R3

  class NewRailsRouter
  
    include Rack::Router::Routable
 
    def initialize
      self.configuration_files = []
      @routes = []
    end
  
    def draw(options={}, &block)
      options[:builder] = R3::RailsBuilder
      prepare(options, &block)
    end
    
    include R3::InitializationInterface
  end
  
end