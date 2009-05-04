require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "R3::Router#generate" do
  
  describe "with hash based routes routes" do
    
    it "should generate from hash even if no routes are defined" do
      router.draw {|map| }
      params = {:controller => 'posts', :action => 'index', :algo_mais => 1, :format => 'xml'} 
      pending("This is important, it'll be done soon") do
        url_for(params).should == '/posts.xml?algo_mais=1'
      end
    end
    
  end
  
end