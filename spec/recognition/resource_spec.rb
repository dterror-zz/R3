require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# Refactor after rewrite of restful routes testing

describe "With RESTful routes" do
   
   it "should understand basic resources dsl" do     
      router.draw {|map| map.resources :photos }

      unfold_resourceful_routeset :photos  
   end
   
   it "should define many routes at the same time" do
     router.draw {|map| map.resources :photos, :posts, :comments }
     
     unfold_resourceful_routeset :photos
     unfold_resourceful_routeset :posts
     unfold_resourceful_routeset :comments
   end
   
   it "should understand singleton resource" do
     router.draw {|map| map.resource :page }

     unfold_singleton_resource_routeset :page
   end
   
   describe "Provided Options" do
     
     it "should understand :controller" do
       router.draw {|map| map.resources :photos, :controller => 'images' }
       
       unfold_resourceful_routeset :photos, :controller => 'images'
     end
     
     it "should enforce requirements" do
       router.draw {|map| map.resources :posts, :requirements => { :id => /\d{2}/ } }
       
       route_for('/posts/12').should have_route(PostsController, :action => 'show', :id => '12')
       route_for('/posts/2').should be_missing
     end
     
     it "should understand :as" do
       router.draw {|map| map.resources :photos, :as => 'images' }
       
       route_for('/images').should have_route(PhotosController, :action => 'index')
     end
     
     it "should understand :path_names" do
       router.draw {|map| map.resources :photos, :path_names => { :new => 'make', :edit => 'change' } }
       
       route_for('/photos/make').should have_route(PhotosController, :action => 'new')
       route_for('/photos/1/change').should have_route(PhotosController, :action => 'edit', :id => '1')
     end
     
     it "should understand :path_prefix" do
       router.draw {|map| map.resources :photos, :path_prefix => '/amazing' }
     
       route_for('/amazing/photos').should have_route(PhotosController, :action => 'index')
       route_for('/photos').should be_missing
     end
     
     it "should understand :name_prefix" do
       router.draw {|map| map.resources :photos, :name_prefix => 'someone_'}
       # this is uggly, but the real route generation test would have to stub rails environment
       router.routes[0].name.should == :someone_photos
     end
     
     it "should understand :only" do
       router.draw {|map| map.resources :photos, :only => :index }
       
       route_for('/photos').should have_route(PhotosController, :action => 'index')
       route_for('/photos', :method => 'POST').should be_missing
     end
     
     it "should understand :except" do
       router.draw {|map| map.resources :photos, :except => [:destroy, :create] }
       
       route_for('/photos').should have_route(PhotosController, :action => 'index')
       route_for('/photos/1/edit').should have_route(PhotosController, :action => 'edit', :id => '1')
       route_for('/photos', :method => 'POST').should be_missing
       route_for('/photos/1', :method => 'DELETE').should be_missing
       # route_for('/photos/new', :method => 'GET').should be_missing It tryes to show with :id => 'new'
     end
     
     it "should understand :all and :none with :only and :except" do
       router.draw {|map| map.resources :photos, :except => :none }

       unfold_resourceful_routeset :photos
     end
     
     it "should understand with_options" do
       router.draw  do |map|
         map.with_options :only => :index do |index_only|
           index_only.resources :posts
         end
       end
       
       route_for('/posts').should have_route(PostsController)
       route_for('/posts/new').should be_missing
     end
     
   end
   
   describe "Nested resources" do
     
     it "should support basic nested resources" do
       router.draw do |map|
         map.resources :magazines do |magazine|
           magazine.resources :ads
         end
       end
       
       # unfold_resourceful_routeset :magazines
       route_for('/magazines').should have_route(MagazinesController, :action => 'index')
       route_for('/magazines/1/ads').should have_route(AdsController, :action => 'index', :magazine_id => '1')
       route_for('/magazines/5/ads/1/edit').should have_route(AdsController, :action => 'edit', :magazine_id => '5', :id => '1')              
     end
     
     it "should do deeply nested resources" do
       # just because it does, doesn't mean you should :)
       router.draw do |map|
         map.resources :magazines do |magazine|
           magazine.resources :writers do |writer|
             writer.resources :twitter_followers
           end
         end
       end
       
       route_for('/magazines').should have_route(MagazinesController)
       route_for('/magazines/1/writers').should have_route(WritersController, :magazine_id => '1')
       route_for('/magazines/1/writers/5/twitter_followers').should have_route(TwitterFollowersController, :magazine_id => '1', :writer_id => '5')       
     end
     
     it "should do :has_many, activerecord-like" do
       router.draw do |map|
         map.resources :magazines, :has_many => :ads
       end
       # unfold_resourceful_routeset :magazines
       route_for('/magazines').should have_route(MagazinesController, :action => 'index')
       route_for('/magazines/1/ads').should have_route(AdsController, :action => 'index', :magazine_id => '1')
       route_for('/magazines/5/ads/1/edit').should have_route(AdsController, :action => 'edit', :magazine_id => '5', :id => '1')            
     end
     
     it "should do activerecord-like with more than one resource" do
       router.draw do |map|
         map.resources :magazines, :has_many => [:ads, :writers]
       end
       # unfold_resourceful_routeset :magazines
       route_for('/magazines').should have_route(MagazinesController, :action => 'index')
       route_for('/magazines/1/ads').should have_route(AdsController, :action => 'index', :magazine_id => '1')
       route_for('/magazines/5/writers').should have_route(WritersController, :action => 'index', :magazine_id => '5')       
     end     
     
     it "should do :has_one, activerecord-like" do
       router.draw do |map|
         map.resources :magazines, :has_one => :ad
       end
       # unfold_resourceful_routeset :magazines
       route_for('/magazines').should have_route(MagazinesController, :action => 'index')
       route_for('/magazines/1/ad').should have_route(AdsController, :action => 'show', :magazine_id => '1')
       route_for('/magazines/5/ad/1').should be_missing
     end
     
     it "should understand shallow nesting" do
       router.draw do |map|
         map.resources :posts, :shallow => true do |post|
           post.resources :comments
         end
       end
       
       route_for('/posts').should have_route(PostsController)
       route_for('/posts/5/comments').should have_route(CommentsController, :action => 'index', :post_id => '5')
       route_for('/comments/1').should have_route(CommentsController, :action => 'show', :id => '1')
     end
     
   end
   
 
   describe "Additional RESTful Routes" do
     
     it "should add simple member actions" do
       router.draw {|map| map.resources :posts, :member => { :original => :get } }
            
       route_for('/posts').should have_route(PostsController)
       route_for('/posts/1/original').should have_route(PostsController, :action => 'original', :id => '1')
       route_for('/posts/1/original', :method => 'PUT').should be_missing
     end
     
     it "should add collection action" do
       router.draw {|map| map.resources :posts, :collection => { :latests => :get, :search => :get } }
       
       route_for('/posts').should have_route(PostsController)
       route_for('/posts/latests').should have_route(PostsController, :action => 'latests')
       route_for('/posts/search').should have_route(PostsController, :action => 'search')
     end
     
     it "should add a new action with the :new option" do
       router.draw {|map| map.resources :posts, :new => { :latests => :get } }
       
       route_for('/posts').should have_route(PostsController)
       pending("Special case, down in the priority list") do
         route_for('/posts/latests').should have_route(PostsController, :action => 'latests')
       end
     end
          
   end
   
   describe "Mapping namespace" do
     
     it "should map to namespaced controller" do
       router.draw do |map|
         map.namespace(:admin) do |admin|
            admin.resources :posts        
         end
       end
       
       class Admin;end
       Admin::PostsController = AnystubController # just so that const_missing does its magic
       
       route_for('/admin/posts').should have_route(Admin::PostsController)
     end
     
   end
 
end

























