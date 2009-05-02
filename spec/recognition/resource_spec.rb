require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "With RESTful routes" do
   
   it "should understand resources dsl" do
      router.draw {|map| map.resources :poststub, :only => :index }
      
      puts router.routes.inspect
      
      route_for('/poststub').should have_route(PoststubController, :action => 'index')
   end
   
end