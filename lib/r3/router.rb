module R3

  class Router
  
    include Rack::Router::Routable
 
    def initialize
      self.configuration_files = []
      @routes = []
    end
  
    def draw(options={}, &block)
      options[:builder] = R3::Builder
      prepare(options, &block)
    end
    
    include R3::InitializationInterface
    
  end
  
end