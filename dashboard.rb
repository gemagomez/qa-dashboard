require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'sinatra'
require 'logger'

require 'haml'

require './db.rb'


configure do
  dbconfig = YAML::load(File.open('config/database.yml'))

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.establish_connection(dbconfig)

  ActiveRecord::Base.include_root_in_json = false

end

after do
  ActiveRecord::Base.clear_active_connections!
end

get "/css/style.css" do
  scss :style, :style => :expanded
end


get "/" do
  @jobs = Job.all
  haml :jobs

end
