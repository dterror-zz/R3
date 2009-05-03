require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "R3::Router#generate" do
  
  describe "with hash based routes routes" do
    it "should generate routes for hashes" do
      router.draw {|map| map.connect ':controller/:action/:id' }
      
      url_for(:controller => 'posts', :action => 'show', :id => '1').should == '/posts/show/1'
    end
  end
  
end