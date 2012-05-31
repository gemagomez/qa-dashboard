require 'sinatra'
require 'dalli'
require 'rack/cache'

set :env,  :production
disable :run

require './dashboard.rb'

config = YAML::load(File.open('config/config.yml'))

require 'rack/cache/key'
require 'rack/utils'

module Rack::Cache
  class Key
    # Generate a normalized cache key for the request.
    def generate
      parts = []
      parts << @request.session['user'] if defined? @request.session['user']
      parts << @request.scheme << "://"
      parts << @request.host

      if @request.scheme == "https" && @request.port != 443 ||
          @request.scheme == "http" && @request.port != 80
        parts << ":" << @request.port.to_s
      end

      parts << @request.script_name
      parts << @request.path_info

      if qs = query_string
        parts << "?"
        parts << qs
      end

      parts.join
    end
  end
end

if not config['cache'].nil? and config['cache']['store'] == 'memcache'
  puts "Using Rack::Cache"
  use Rack::Cache,
    :allow_reload     => false,
    :allow_revalidate => true,
    :verbose     => !config['silent'],
    :metastore   => 'memcached://' + config['cache']['location'] + '/' + config['cache']['key_prefix'] + ':meta',
    :entitystore => 'memcached://' + config['cache']['location'] + '/' + config['cache']['key_prefix'] + ':body'
end

run Sinatra::Application
