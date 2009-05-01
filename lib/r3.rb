require 'rubygems'
require 'rack/router'
$LOAD_PATH.unshift File.dirname(__FILE__)

module R3
  autoload :Router,                   'r3/router'
  autoload :InitializationInterface,  'r3/initialization_interface'
  autoload :Builder,                  'r3/builder'
end




