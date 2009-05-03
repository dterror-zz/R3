require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "R3::Router#generate" do
  
  describe "with named routes" do

    it "should generate default named routes" do
      router.draw {|map| map.resources :posts }
    
      posts_path.should == '/posts'
      new_post_path.should == '/posts/new'
      post = AR::Post.find(1)
      post_path(post).should == '/posts/1'
      edit_post_path(post).should == '/posts/1/edit'    
    end
    
    it "should understand working with AR instances" do
      router.draw {|map| map.resources :posts }
      
      post = AR::Post.find(12)
      url_for(post).should == '/posts/12'
      url_for(post).should_not == '/posts/1'
    end
    
    it "should understand working with new AR instances" do
      router.draw {|map| map.resources :posts }
      
      url_for(AR::Post.new).should == '/posts'
    end

  end
  
end