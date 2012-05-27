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
  @builds = []
  build_ids = Result.select(:description).uniq.map { |result| result.description }

  for id in build_ids
    successes = Result.where(:description => id, :result => "SUCCESS").count
    total = Result.where(:description => id).count
    pass_rate = (total == 0) ? 0.0 : successes.to_f/total.to_f;
    @builds << { :id => id, 
                 :pass => successes, 
                 :fail => (total.to_i - successes.to_i), 
                 :total => total, 
                 :pass_rate => pass_rate }
  end

#  @builds = []
#  Result.select(:description).uniq.each do |result|
#    id = result.description
#    successes = Result.where(:description => id, :result => "SUCCESS").count
#    total = Result.where(:description => id).count
#    pass_rate = (total == 0) ? 0.0 : successes.to_f/total.to_f;
#    @builds << { :id => id, :pass_rate => pass_rate }
#  end

  haml :build_overview
end

get "/build/:build" do
  @build_id = params[:build]
  puts "build #{params[:build]}"
  @results_build = Result.where(:description => params[:build])

  haml :results_build

end

get "/jobs" do
  @jobs = Job.all
  haml :jobs

end
