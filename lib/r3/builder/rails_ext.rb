# Adding support to rack-router's builder/simple dsl
class ActionController::Routing::RouteSet::Mapper
    def map(*args)
       route = Rack::Router::Builder::Simple.new.map(*args).pop
       @set.add_route_directly(route)
    end

    alias :mount :map
end