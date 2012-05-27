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
  build_ids = Result.select(:description).uniq.order("description DESC").map { |result| result.description }

  for id in build_ids
    if(id =~ /[0-9]{8}.*/) 
      successes = Result.where(:description => id, :result => "SUCCESS").count
      total = Result.where(:description => id).count
      pass_rate = (total == 0) ? 0.0 : successes.to_f/total.to_f
      # TODO: Add bug counter and link to bugs
      bugs = 0

      # colour coding the results
      if(pass_rate > 0.9 ) 
        color = "green"
      elsif (pass_rate <= 0.9) and (pass_rate > 0.6) 
        color = "orange"
      else 
        color = "red" 
      end 

      @builds << { :id => id, 
                   :pass => successes, 
                   :fail => (total.to_i - successes.to_i), 
                   :total => total, 
                   :pass_rate => pass_rate,
                   :color => color, 
                   :bugs => bugs
                  }
    end
  end

  haml :build_overview
end

get "/build/:build" do
  @build_id = params[:build]
  puts "build #{params[:build]}"
  @results_build = Result.where(:description => params[:build])
  
  @total_tests = 0
  @total_fail = 0
  @total_skipped = 0

  for result in @results_build
    puts result.to_s
    @total_fail += result.failcount.to_i
    @total_skipped += result.skipcount.to_i
    @total_tests += result.totalcount.to_i
  end

  haml :results_build

end

get "/jobs" do
  @jobs = Job.all
  haml :jobs

end
