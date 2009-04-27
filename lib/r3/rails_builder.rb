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

end