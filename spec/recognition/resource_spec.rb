require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "With RESTful routes" do
   
   it "should understand basic resources dsl" do
     
      router.draw {|map| map.resources :photos }

      unfold_restful_routeset :photos  
   end
   
end