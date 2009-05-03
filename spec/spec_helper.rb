# Most parts are ripped-off from rack-router's spec helper.

# Refactor this thing. Use a proper stubing framekwork or something
# remove the unfolding of restful routes thing. Tough the intention is good, it really sucks


$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
RAILS_ROOT = File.dirname(__FILE__)
require "rubygems"
require "spec"
require "rack/router"
require 'r3'
 
module Spec
  module Helpers
    
    def draw(options={}, &block)
      router.draw(options,&block)
    end
    
    def initialized?
       @initialized ||= false
    end
    
    def init
       return if initialized?
       gem 'rails'
       require 'initializer'
       Rails::Initializer.run(:require_frameworks) do |config|
          config.frameworks -= [:active_record, :active_resource, :action_mailer] #anything else?
       end
       @initialized = true
    end

    
    def router
       init
       @app ||= R3::Router.new
    end
    
    
    def make_router_and_draw(options={},&block)
       R3::Router.new.draw(options={},&block)
    end
    
    
    def env_for(path, options = {})
      env = {}
      env["REQUEST_METHOD"]  = (options.delete(:method) || "GET").to_s.upcase
      env["REQUEST_URI"]     = ((options[:script_name] || "/") + path).squeeze("/")
      env["PATH_INFO"]       = path.squeeze("/").sub(%r'/$', '').sub(/\?.*\Z/,'')
      env["SCRIPT_NAME"]     = options.delete(:script_name) || "/"
      env["HTTP_HOST"]       = options.delete(:host) || "example.org"
      env["rack.url_scheme"] = options[:scheme] if options[:scheme]
      env["rack_router.testing"] = "1"
      env
    end
    
    
    def route_for(path, options = {})
      @app.call env_for(path, options)
    end
    
    
    def url_for(arg)
      case arg
      when AR::ActiveRecordStub
        model = arg
        route_name = "#{model.class.to_s.downcase}_path"
        send(route_name.to_sym, model)
      when Hash
        # app generate doesn't support this
        @app.generate(arg)
      end
    end
    
    def method_missing(name, *args)
      # testing only _path methods, _url is a rails thing. It's supposed to work
      # refactor, boy, refactor this whole helper thing...
      if name.to_s =~ /(\w+)_path$/
        params = {}
        params.update(args.pop) if args.last.is_a?(Hash)
        model = args[0]
        # building the mocked rails options hash
        options = {}
        options[:use_route] = $1.to_sym
        options[:id] = model if model
        options.update(params)#.update(current_request_params)
        @app.generate(options)
      else
        super(name, *args)
      end
    end
    
    
    def unfold_resourceful_routeset(resource_name, options = {})
      # Rewrite this
      
      # GET /<resource_name>      
      route_for("/#{resource_name}", :method => 'GET').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                        :action => 'index'
                                                                      )

      # GET /<resource_name>/new
      route_for("/#{resource_name}/new", :method => 'GET').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                       :action => 'new'
                                                                       )

      # POST /<resource_name>
      route_for("/#{resource_name}", :method => 'POST').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                       :action => 'create')

      # GET /<resource_name>/1
      route_for("/#{resource_name}/1", :method => 'GET').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                       :action => 'show', :id => '1')

      # GET /<resource_name>/1/edit
      route_for("/#{resource_name}/1/edit", :method => 'GET').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                       :action => 'edit', :id => '1')

      # PUT /<resource_name>/1
      route_for("/#{resource_name}/1", :method => 'PUT').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                       :action => 'update', :id => '1')

      # DELETE /<resource_name>/1
      route_for("/#{resource_name}/1", :method => 'DELETE').should have_route(
                                                                      "#{(options[:controller]||resource_name).to_s.camelize}Controller",
                                                                       :action => 'destroy', :id => '1')
    end
    
    def unfold_singleton_resource_routeset(resource_name)
      # rewrite this
      
      # GET /<resource_name>      
      route_for("/#{resource_name}", :method => 'GET').should have_route("#{resource_name.to_s.camelize}sController", :action => 'show')

      # GET /<resource_name>/new
      route_for("/#{resource_name}/new", :method => 'GET').should have_route("#{resource_name.to_s.camelize}sController", :action => 'new')

      # POST /<resource_name>
      route_for("/#{resource_name}", :method => 'POST').should have_route("#{resource_name.to_s.camelize}sController", :action => 'create')

      # GET /<resource_name>/1
      route_for("/#{resource_name}/1", :method => 'GET').should be_missing

      # GET /<resource_name>/edit
      route_for("/#{resource_name}/edit", :method => 'GET').should have_route("#{resource_name.to_s.camelize}sController", :action => 'edit')

      # PUT /<resource_name>
      route_for("/#{resource_name}", :method => 'PUT').should have_route("#{resource_name.to_s.camelize}sController", :action => 'update')

      # DELETE /<resource_name>
      route_for("/#{resource_name}", :method => 'DELETE').should have_route("#{resource_name.to_s.camelize}sController", :action => 'destroy')      
    end

  end

  

  
  
  
  module Matchers
    
    class HaveRoute
      def initialize(app, expected)
        @app, @expected = app, expected
      end
      
      def matches?(target)
        @target = target
        
        if @target[0] == 200
          @resp  = Marshal.load(@target[2])
          params = @resp['rack_router.params']
           # it already tests match of app (contoller), so reject controller param
           @app.to_s == @resp['app'] && @expected == params.reject {|k,v| k == :controller }
         end
      end
      
      def failure_message
        if @resp
          # "Route matched, but returned: #{@resp['app']} with #{@resp['routing_args'].inspect}"
          "Route matched, but returned: #{@resp.inspect}"
        else
          "Route did not match anything"
        end
      end
    end
    
    def have_route(app, expected = {})
      # if it's a route to rails, add rails defaults to expected so I don't need to type them everytime
      if app.to_s.match /[A-Z]{1}[a-z]+Controller$/
        expected = R3::Builder::DEFAULT_PARAMS.merge(expected)
      end
      HaveRoute.new(app, expected)
    end
    
    def have_env(env)
      simple_matcher "the request to have #{env.inspect}" do |given, m|
        given_env = Marshal.load(given[2]) rescue nil
        
        m.failure_message = given[0] == 200 ?
          "expected the request to contain #{env.inspect}, but it was #{given_env.inspect}" :
          "the route could not be matched"
          
        given[0] == 200 && env.all? { |k, v| given_env[k] == v }
      end
    end
    
    def be_missing
      simple_matcher("a not found request") do |given, m|
        env = Marshal.load(given[2]) rescue nil
        
        m.failure_message = "expected the request to not match, but it did with: #{env.inspect}"
        given[0] == 404
      end
    end
    
    def have_status_code
      simple_matcher("a request") do |given, m|
        env = Marshal.load(given[2]) rescue nil
        
        m.failure_message = "expected the request to have a status code, but it didn't: #{env.inspect}"
        success_codes = [200, 201, 203, 204]
        error_codes = [400, 401, 402, 403, 404, 500, 501, 502, 503]
        redirect_codes = [301, 302, 303, 304]
        status_codes = success_codes + error_codes + redirect_codes
        status_codes.include? given[0]
      end
    end
    
    def have_headers
      simple_matcher("a request") do |given, m|
        env = Marshal.load(given[2]) rescue nil
        
        m.failure_message = "expected the request to have a header hash, but it didn't: #{env.inspect}"
        given[1].kind_of? Hash
      end
    end
    
    def have_valid_body
      simple_matcher("a request") do |given, m|
        env = Marshal.load(given[2]) rescue nil
        if (RUBY_VERSION.to_f < 1.9) && given[2].kind_of?(String)
          puts "*** WARNING: Ruby 1.9 does not support String#each. Should return an array instead"
        end
        m.failure_message = "expected the request body to accept each, but it didn't: #{env.inspect}"
        given[2].respond_to? :each
      end
    end
    
  end
end
 
class FailApp
  def self.call(env)
    [ 400, { "Content-Type" => 'text/html' }, "418 I'm a teapot" ]
  end
end

# Beautiful
module AR  
  class ActiveRecordStub
    def self.find(num)
      new(num)
    end
    
    def initialize(record_id=nil)
      @record_id = record_id
    end
    
    def new_record?
      @record_id.nil?
    end
    
    def to_param
      @record_id
    end 
  end
  
  instance_eval do
    def const_missing(name)
      # const_set(name, ActiveRecordStub)
      instance_eval "class ::#{name} < ActiveRecordStub;end ; ::#{name}"
    end
  end
end

Object.instance_eval do
  def const_missing(name)
    if name.to_s =~ /App$|[A-Z]{1}[a-z]+Controller$/
      # super unless $1 == "Action"
      Object.instance_eval %{
        class ::#{name}
          def self.call(env)
            env.delete("rack_router.route")
            [ 200, { "Content-Type" => 'text/yaml' }, Marshal.dump(env.merge("app" => "#{name}")) ]
          end
        end
        ::#{name}
      }
    else
      super
    end
  end
end
 
Spec::Runner.configure do |config|
  config.include(Spec::Helpers)
  config.include(Spec::Matchers)
end