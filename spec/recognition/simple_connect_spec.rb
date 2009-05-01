require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Simple connect recognition" do
   
   it "should connect simple url to controller" do
      router.draw {|map| map.connect '/hello', :controller => 'hellostub' }
      
      route_for('/hello').should have_route(HellostubController, {:action => 'index'})
   end
   
end