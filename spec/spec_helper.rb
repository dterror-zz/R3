# Shameless rip of from rack-router's spec helper.
# These helpers should be distributed, really.

# I could work aroung having to repeatedely specify :action => 'index', but I think
# it's best to keep it explicit for readability and I reckon It'll keep me from making mistakes.


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
    
    # def prepare(options={}, &block)
    #    options[:builder] = Rack::Router::Builder::Simple
    #    router.prepare(options,&block)
    # end
    
    def router
       init
       @app ||= R3::Router.new
    end
    
    # def make_router_and_prepare(options={}, &block)
    #    new_router = R3::Router.new
    #    options[:builder] = Rack::Router::Builder::Simple
    #    new_router.prepare(options,&block)
    #    new_router
    # end
    
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
  end
  
  module Matchers
    
    class HaveRoute
      def initialize(app, expected, exact)
        @app, @expected, @exact = app, expected, exact
      end
      
      def matches?(target)
        @target = target
        
        if @target[0] == 200
          @resp  = Marshal.load(@target[2])
          params = @resp['rack_router.params']
          @app.to_s == @resp['app'] && @expected == params.reject {|k,v| k == :controller || v == nil }
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
      HaveRoute.new(app, expected, false)
    end
    
    def have_exact_route(app, expected = {})
      HaveRoute.new(app, expected, true)
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
 
Object.instance_eval do
  def const_missing(name)
    if name.to_s =~ /[App|stubController]$/
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