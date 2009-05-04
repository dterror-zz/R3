require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "R3::Router#generate" do
  
  describe "with named routes" do

    it "should generate default named routes" do
      router.draw {|map| map.resources :posts }
    
      posts_path.should == '/posts'
      new_post_path.should == '/posts/new'
      post = AR::Post.find(1)
      post_path(post).should == '/posts/1'
      post_path(1).should == '/posts/1'
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
    
    it "should include non-resourceful named routes" do
      router.draw {|map| map.login '/login', :controller => 'sessions', :action => 'new' }
      
      login_path.should == '/login'
    end
    
    it "should unerstand the singular option" do
      router.draw {|map| map.resources :teeth, :singular => 'tooth' }
      
      teeth_path.should == '/teeth'
      new_tooth_path.should == '/teeth/new'
    end
    
    it "should understand name_prefix options" do
      router.draw {|map| map.resources :posts, :path_prefix => '/blog', :name_prefix => 'blog_' }
      
      blog_posts_path.should == '/blog/posts'
      new_blog_post_path.should == '/blog/posts/new'
    end
    
    it "should understand nested routes" do
      router.draw {|map| map.resources :posts, :has_many => :comments }

      post = AR::Post.find(1)
      comment = AR::Comment.find(5)
      post_comments_path(post).should == '/posts/1/comments'
      post_comment_path(post, comment).should == '/posts/1/comments/5'
    end
    
    it "should understand shallow nesting" do
      router.draw {|map| map.resources :posts, :has_many => :comments, :shallow => true }
      post = AR::Post.find(5)
      comment = AR::Comment.find(1)
      post_comments_path(post).should == '/posts/5/comments'
      comment_path(comment).should == '/comments/1'
      edit_comment_path(comment).should == '/comments/1/edit'
    end
    
    
    it "works with segments in path_prefix" do
      # should test it with blog_num set with a default
      router.draw {|map| map.resources :posts, :path_prefix => '/blog/:blog_num' }
      
      posts_path(:blog_num => '1').should == '/blog/1/posts'
    end
    
    #  It does work, I need a better spec_helper for this thing. One that mocks reliably
    #
    #  
    # it "should add named_routes for custom member actions" do
    #   router.draw {|map| map.resources :posts, :member => { :original => :get } }
    #   post = AR::Post.find(1)     
    #   original_post_path(post).should == '/posts/1/original'
    # end
    # 
    # it "should add collection action" do
    #   router.draw {|map| map.resources :posts, :collection => { :latests => :get, :search => :get } }
    # 
    #   latests_photos_path.should == '/posts/latests'
    #   search_photos_path.should == '/posts/search'
    # end

  end
  
end










