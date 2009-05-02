# From rack-router's spec suit. This one has to comply too
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
 
describe "Rack::Router behaviour in R3::Router" do
  
  it "updates PATH_INFO and SCRIPT_NAME correctly when calling child apps" do
    router.draw do |r|
      r.map "/hello", :to => HelloApp
    end
    
    route_for("/hello").should have_env("PATH_INFO" => "", "SCRIPT_NAME" => "/hello")
  end
  
  it "updates PATH_INFO and SCRIPT_NAME correctly in child routers" do
    router.draw do |r|
      r.map "/hello", :to => make_router_and_draw { |c| c.map "/world", :to => HelloApp }
    end
    
    route_for("/hello/world").should have_env("PATH_INFO" => "", "SCRIPT_NAME" => "/hello/world")
  end
  
  # Check what's going on with this one
  it "does not let updated PATH_INFO and SCRIPT_NAME bleed across routes" do
    router.draw do |r|
      r.map "/hello", :to => make_router_and_draw { |c| c.map "/world", :to => WorldApp }
      r.map "/hello", :to => make_router_and_draw { |c| c.map "/america", :to => AmericaApp }
    end
    
    route_for("/hello/america").should have_env("PATH_INFO" => "", "SCRIPT_NAME" => "/hello/america")
  end
  
  it "leaves the REQUEST_URI env variable as is throughout child routers" do
    router.draw do |r|
      r.map "/hello", :to => make_router_and_draw { |c| c.map "/world", :to => WorldApp }
    end
    
    route_for("/hello/world").should have_env("REQUEST_URI" => "/hello/world")
  end
  
end