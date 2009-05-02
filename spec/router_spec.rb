require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Basic R3::Router" do

   # Bear in mind that this does not test the integration with Rails
   # write a test for that too, eventually.
   # The Vital parts of it are:
   # 1) Check that ActionController::Routing::Routes is an instance of R3::Router
   # 2) Check that env['rack_router.params'] got merged into the target controller params hash
   # 3) Check it routes to the correct controller
   # 4) Check it returns a no routes match error instead of 'misterious' 404
   
   describe "escaping special characters in conditions" do   
      it "allows : to be escaped" do
        router.draw { |r| r.map '/hello/\:world', :to => FooApp }
        route_for('/hello/:world').should have_route(FooApp)
        route_for('/hello/fail').should be_missing
      end
         
      it "allows * to be escaped" do
        router.draw { |r| r.map '/hello/\*world', :to => FooApp }
        route_for('/hello/*world').should have_route(FooApp)
        route_for('/hello/fail').should be_missing
      end
      
      it "allows ( to be escaped" do
        router.draw { |r| r.map '/hello/\(world', :to => FooApp }
        route_for('/hello/\(world').should have_route(FooApp)
      end
      
      it "allows ) to be escaped" do
        router.draw { |r| r.map '/hello/\)world', :to => FooApp }
        route_for('/hello/\)world').should have_route(FooApp)
      end
      
      it "should deal with querystrigs" do
         router.draw {|map| map.connect ':controller/:action/:id' }

         # user_id won't be available in the params hash beacuse this is something that rails does
         # and is out of the scope of this spec. Just got this test here to remember this detail
         route_for('/hellostub?user_id=12').should have_route(HellostubController, :action => 'index')
      end
      
    end
   
   describe "Meta Spec" do      
      it "should call the stub controller correctly" do
         router.draw {|map| map.connect '/hello', :controller => 'hellostub' }
         route_for('/hello').should be_a_kind_of Array
      end
      
      it "should return rack 404 on route not found" do
         router.draw {|map| map.connect '/hello', :controller => 'hellostub' }
         route_for('nada')[0].should_not  == 200
      end
      
      it "it rejecs the implicit and unused params" do
         router.draw {|map| map.connect '/hello', :controller => 'hellostub' }
         route_for('/hello').should  have_route(HellostubController, {:action => 'index'})
      end   
   end
   
   describe "rack-router builder integration" do
      it "should suport the map method" do
         dsl_block = lambda {|map| map.map '/hello', :to => HelloApp }
         router.draw(&dsl_block).should_not raise_error(NameError, ArgumentError)
      end
   end
   
   
   # Test the initialization interface!
   
   # Test that it corrently passes the rails builder on #draw 
   
end