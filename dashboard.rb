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
  # XXX: put default release in config file
  redirect '/smoke/quantal'
end

# Smoke testing aggregated view for a release 
get "/smoke/:release" do
  @release  = params[:release]
  @releases = Run.select(:release).uniq.order("release DESC").map { |run| run.release }
  @runs = Run.where(:release => @release)

  haml :smoke_overview
end

# Smoke testing aggregated view for a particular build_no and release
get "/smoke/:release/run/:id" do
  @release = params[:release]
  @run     = Run.find(params[:id])
  @builds  = @run.builds

  haml :smoke_build_overview
end

get "/smoke/:release/run/:run_id/image/:image_id" do
  @release  = params[:release]
  @image    = Build.find(params[:image_id])
  @results  = @image.results

  haml :smoke_results
end

# XXX: Move this to the data model when the table results and the table builds are available
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



