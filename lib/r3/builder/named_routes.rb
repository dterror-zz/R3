class R3::Builder

  # This is just a stub so that rails thinks it exists
   class NamedRoutes
      attr_accessor :routes
   
      def initialize
        @routes = {}
      end
   
      def <<(route)
         @routes[route.name] = route
      end
      
      def [](route_name)
         @routes[route_name.to_sym]
      end
      
   end

end