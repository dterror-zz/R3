class R3::Builder
      
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
   
end