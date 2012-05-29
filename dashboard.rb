require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'sinatra'
require 'logger'

require 'haml'

require './db.rb'
require './view_helpers.rb'
require './easyplot.rb'

include EasyPlot


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
    if (id =~ /[0-9]{8}.*/)
      results = Result.where(:description => id)
      failed = 0
      total = 0
      results.each do |res|
        failed += res.failcount.to_i + res.skipcount.to_i
        total  += res.totalcount.to_i
      end
      successes = total.to_i - failed.to_i
      pass_rate = (total == 0) ? 0.0 : successes/total.to_f
      # TODO: Add bug counter and link to bugs
      bugs = 0

      @builds << { :id => id, 
                   :pass => successes, 
                   :fail => (total.to_i - successes.to_i), 
                   :total => total, 
                   :pass_rate => pass_rate,
                   :bugs => bugs
                  }
    end
  end

  haml :build_overview
end

# Move this to the data model when the table results and the table builds are available
get '/build/pie/:build' do
  content_type :png
  @build_id = params[:build]
  @results_build = Result.where(:description => params[:build])


  total_tests = 0
  total_fail = 0
  total_skip = 0
  total_pass = 0

  for result in @results_build
    total_fail += result.failcount.to_i
    total_skip += result.skipcount.to_i
    total_tests += result.totalcount.to_i
    total_pass = total_tests - total_skip - total_fail
  end

  data = {}

  data['Passed'] = { :value => total_pass, :color => "#abffab" } if total_pass > 0
  data['Failed'] = { :value => total_fail, :color => "#ffabab" } if total_fail > 0
  data['Skipped'] = { :value => total_skip, :color => "#dd4814" } if total_skip > 0

  EasyPlot::EasyPlot.pie_chart data, { :width => 400, :height => 400, :explosion => 2, :font => { "tahoma.ttf" => 10 }}
end


get "/build/:build" do
  @build_id = params[:build]
  @results_build = Result.where(:description => params[:build])


  @total_tests = 0
  @total_fail = 0
  @total_skipped = 0

  for result in @results_build
    @total_fail += result.failcount.to_i
    @total_skipped += result.skipcount.to_i
    @total_tests += result.totalcount.to_i
  end
  


  haml :results_build

end
