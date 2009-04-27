module R3

  class NewRailsRouter
  
    include Rack::Router::Routable
  
    attr_accessor :configuration_files
 
    def initialize
      self.configuration_files = []
      @routes = []
    end
  
    def draw(options={}, &block)
      prepare(options, &block)
    end

    def add_configuration_file(path)
      self.configuration_files << path
    end
  
    def routes_changed_at
      routes_changed_at = nil
    
      configuration_files.each do |config|
        config_changed_at = File.stat(config).mtime

        if routes_changed_at.nil? || config_changed_at > routes_changed_at
          routes_changed_at = config_changed_at 
        end
      end
    
      routes_changed_at
    end
  
    def load!
      clear!
      load_routes!
    end
    alias reload! load!    

    def clear!  
      routes.clear
    end
  
    def load_routes!
      if configuration_files.any?
        configuration_files.each { |config| load(config) }
        @routes_last_modified = routes_changed_at
      else
        #add a basic route here ':controller/:action/:id'
      end  
    end
  
    def reload
      if configuration_files.any? && @routes_last_modified
        if routes_changed_at == @routes_last_modified
          return # routes didn't change, don't reload
        else
          @routes_last_modified = routes_changed_at
        end
      end
    
      load!
    end
  end
  
end