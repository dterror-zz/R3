require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "With named routes definition" do
   
   # route generation is another spec,
   # so, this is a simple test to make sure it works like the rest
   
   it "should work like simple connects" do
      router.draw do |map|
         map.logout '/logout', :controller => 'sessionstub', :action => 'destroy'
      end
      
      route_for('/logout').should have_route(SessionstubController, :action => 'destroy')
   end
   
   it "should support synamic segments" do
      router.draw {|map| map.default ':controller/:action/:id' }
      route_for('/hellostub').should have_route(HellostubController, :action => 'index')
   end
   
   it "should map to root" do
      router.draw {|map| map.root :controller => 'homestub' }
   
      route_for('/').should have_route(HomestubController, :action => 'index')
   end
   
   it "should support map root to another already defined named route" do
      router.draw do |map|
         map.index 'index', :controller => 'homestub'
         map.root :index
      end
      route_for('/').should have_route(HomestubController, :action => 'index')
   end
   
   it "should support mapping to an empty string" do
      router.draw {|map| map.connect '', :controller => 'homestub' }
      
      route_for('/').should have_route(HomestubController, :action => 'index')
   end
   
end