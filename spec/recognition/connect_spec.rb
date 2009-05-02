require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# Maybe remove the unnecessary explicit use of defaults. Could just ignore the :action => 'index' thing
# but it may be good for undersntadment

describe "static segments connect recognition" do
   
   it "should connect simple url to controller" do
      router.draw {|map| map.connect '/hello', :controller => 'hellostub' }
      
      route_for('/hello').should have_route(HellostubController)
      route_for('/hello/world').should be_missing
   end
   
   it "should pass defaults to controller" do
      router.draw {|map| map.connect '/hello', :controller => 'hellostub', :action => 'new'  }

      route_for('/hello').should have_route(HellostubController, :action => 'new')
   end

end

describe "Dynamic segment connect recognition" do
   
   it "should map segments" do
      router.draw {|map| map.connect ':controller/:action/:id' }
      
      route_for('/hellostub/edit/1').should have_route(HellostubController,
                                                         :action => 'edit', :id => "1" )
   end

   it "should deal with rails defaults" do
      # which are :action => 'index', :id => nil
      router.draw {|map| map.connect ':controller/:action/:id' }
      
      route_for('/hellostub').should have_route(HellostubController, :action => 'index')
      route_for('/hellostub/index').should have_route(HellostubController, :action => 'index')
   end

   it "should map segments plus format" do
      router.draw {|map| map.connect ':controller/:action/:id.:format' }
      
      route_for('/hellostub/edit/1.xml').should have_route(HellostubController,
                                                                  :action => 'edit', :id => "1",
                                                                   :format => 'xml')
   end
   
   it "should understand required segments" do
      router.draw {|map| map.connect ':controller/:slugfield', :action => 'show' }

      route_for('/hellostub').should be_missing
   end
   
   it "should understand optional segments when defaults are specified" do
      router.draw {|map| map.connect ':controller/:slugfield', :action => 'show',
                                                               :slugfield => 'default_thing' }
      
      route_for('/hellostub').should have_route(HellostubController,
                                                      :action => 'show', :slugfield => 'default_thing')
   end

   it "should understand optional segments with optional syntax" do
      router.draw {|map| map.connect ':controller(/:slugfield)', :action => 'show' }
      
      route_for('/hellostub').should have_route(HellostubController, :action => 'show')
   end
   
   it "should understand nested optional segments with optional syntax" do
      router.draw {|map| map.connect ':controller(/:slugfield(/:version))', :action => 'show' }
      
      route_for('/hellostub').should have_route(HellostubController, :action => 'show')
      route_for('/hellostub/my_post').should have_route(HellostubController,
                                                         :action => 'show', :slugfield => 'my_post')      
   end
   
   it "should understand nested optional segments with more than one segment" do
      router.draw {|map| map.connect ':controller(/:slugfield/:version)', :action => 'show' }
      
      route_for('/hellostub/my_post').should be_missing
   end
   
   it "should understand implicit optional segments" do
      router.draw {|map| map.connect ':controller/:action/:id' }
      
      route_for('/hellostub').should have_route(HellostubController, :action => 'index')
   end
   
   # it "should perform globbing" do
   #    router.draw {|map| map.connect '/photo/*rest', :controller => 'hellostub' } 
   #    route_for('/photo/and/rest/of/request').should have_route(HellostubController,
   #                                                                :action => 'index',
   #                                                                :rest => ['and','rest','of','request'])
   # end
   
end

describe "Mixed connect" do
   
   it "should understand static and dynamic segments" do
      router.draw {|map| map.connect '/coolsite/:controller/:action/:id' }
      
      route_for('/coolsite/hellostub/edit/1').should have_route(HellostubController,
                                                                     :action => 'edit', :id => "1")
      route_for('/coolsite/hellostub').should have_route(HellostubController, :action => 'index')
      route_for('/coolsite').should be_missing
   end
end



describe "DSL options" do

   describe "requirements" do  
    
      it "should validate custom segments with regexp" do
         router.draw do |map|
            map.connect '/posts/:custom_id', :controller => 'hellostub',
                                             :requirements => { :custom_id => /\d{2}/ }
         end
      
         route_for('/posts/12').should have_route(HellostubController,
                                                         :custom_id => '12', :action => 'index')
         route_for('/posts/1').should be_missing
      end
   
      it "should validate default segments with regexp" do
         router.draw do |map|
            map.connect ':controller/:action/:id', :controller => 'hellostub',
                                                   :requirements => { :id => /\d+/ }
         end
         
         route_for('/hellostub/edit/125').should have_route(HellostubController,
                                                                     :action => 'edit', :id => '125')
         route_for('/hellostub/edit/me').should be_missing
      end
      
      it "should ignore requirements on action and controller" do
         router.draw do |map|
            map.connect ':controller/:action/:id', :controller => 'hellostub',
                                                   :requirements => { :action => /\d+/,
                                                                        :controller => /\d+/ }
         end
         
         route_for('/hellostub/edit/1').should have_route(HellostubController,
                                                               :action => 'edit', :id => '1')         
      end
   
   end

   describe "defaults" do
   
      it "should pass defaults that are not specified in syntax" do
         router.draw do |map|
            map.connect '/photos/:id', :controller => 'hellostub', :defaults => {:format => 'jpeg'}
         end
      
         route_for('/photos/1').should have_route(HellostubController, :id => '1',
                                                                        :action => 'index',
                                                                        :format => 'jpeg')
      end
      
   end
   
   describe "conditions" do
      
      it "should constrain by method" do
         req_methods = %W[ GET PUT POST DELETE HEAD ]
         req_methods.each do |meth|            

            router.draw { |map| map.connect '/hello', :controller => 'hellostub', :conditions => { :method => meth.to_sym }}
            (req_methods - [meth]).each do |forbidden_method|
               route_for('/hello', :method => forbidden_method).should be_missing
            end
            route_for('/hello', :method => meth).should have_route(HellostubController, :action => 'index')
         end
      end
      
   end
   
end