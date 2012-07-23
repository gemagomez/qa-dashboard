require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'sinatra'
require 'logger'

require 'haml'

require './db.rb'
require './view_helpers.rb'
require './easyplot_gruff.rb'

include EasyPlot


configure do
  ActiveRecord::Base.include_root_in_json = false
end


after do
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
  @runs = Run.where(:release => @release).includes(:builds => { :results => [ :result_bugs ] })

  haml :smoke_overview
end


# Smoke testing aggregated view for a particular build_no and release
get "/smoke/:release/run/:id" do
  @release = params[:release]
  @run     = Run.find(params[:id])
  @builds  = @run.builds.includes(:results => [ :result_bugs ])

  haml :smoke_build_overview
end


get "/smoke/:release/run/:run_id/image/:image_id" do
  @release  = params[:release]
  @image    = Build.find(params[:image_id])
  @results  = @image.results.includes(:result_bugs)

  haml :smoke_results
end


get "/smoke/:release/run/:run_id/image/:image_id/logs/:result_id" do
  @release = params[:release]
  @result  = Result.find(params[:result_id])
  @image   = Build.find(params[:image_id])
  @logs    = @result.result_logs

  haml :smoke_result_logs
end


get "/smoke/:release/run/:run_id/pie" do
  content_type :png

  @run   = Run.includes(:builds => { :results => [ :result_bugs ] }).find(params[:run_id])
  @stats = @run.stats

  EasyPlot::EasyPlot.pie_chart(
    {
      'Passed' => { :value => @stats[:pass_rate], :color => "#abffab" },
      'Failed' => { :value => (1-@stats[:pass_rate]), :color => "#ffabab" }
    },
    {
      :width => 600,
      :font => { "ubuntu-fonts/Ubuntu-R.ttf" => { :color => '#000000', :size => { :marker => 16, :legend => 20 } } }
    }
  )   
end


get "/smoke/:release/run/:run_id/image/:image_id/pie" do
  content_type :png

  @image = Build.includes(:results => [ :result_bugs ]).find(params[:image_id])

  @stats = @image.stats

  EasyPlot::EasyPlot.pie_chart(
    {
      'Passed' => { :value => @stats[:pass], :color => "#abffab" },
      'Failed' => { :value => @stats[:fail], :color => "#ffabab" },
      'Skipped' => { :value => @stats[:skip], :color => "#dd4814" }
    },
    {
      :width => 600,
      :font => { "ubuntu-fonts/Ubuntu-R.ttf" => { :color => '#000000', :size => { :marker => 16, :legend => 20 } } }
    }
  ) 
end

get "/ksru/:release" do
  @release = params[:release]
  @releases = KernelSru.select(:release).uniq.order("release DESC").map { |sru| sru.release }.keep_if{ |rel| not rel.blank? }
  @srus = KernelSru.where(:release => @release)

  puts "srus: #{@srus}"
  haml :sru_overview
end

get "/ksru/:release/sru/:sru_id" do
  @release = params[:release]
  @sru = KernelSru.find(params[:sru_id])
  @results = @sru.kernel_sru_results
  @kernel = "3.0.0-23.38-generic 3.0.36"

  haml :sru_results
end


get "/ksru/:release/sru/:sru_id/pie" do
  content_type :png

  @sru = KernelSru.includes(:kernel_sru_results => [ :kernel_sru_result_bugs ]).find(params[:sru_id])

  @stats = @sru.stats

  EasyPlot::EasyPlot.pie_chart(
    {
      'Passed' => { :value => @stats[:pass], :color => "#abffab" },
      'Failed' => { :value => @stats[:fail], :color => "#ffabab" },
      'Skipped' => { :value => @stats[:skip], :color => "#dd4814" }
    },
    {
      :width => 600,
      :font => { "ubuntu-fonts/Ubuntu-R.ttf" => { :color => '#000000', :size => { :marker => 16, :legend => 20 } } }
    }
  ) 
end

get "/ksru/:release/sru/:sru_id/logs/:result_id" do
  @sru     = KernelSru.find(params[:sru_id])
  @result  = @sru.kernel_sru_results.find(params[:result_id])
  @logs    = @result.result_logs

  haml :smoke_result_logs
end

# API for external users to do their own data manipulation

get "/api/smoke/run" do
  content_type :json
  
  Run.includes(:builds => { :results => [ :result_bugs ] }).all.to_json
end

get "/api/smoke/run/:run_id" do
  content_type :json

  Run.includes(:builds => { :results => [ :result_bugs ] }).find(params[:run_id]).to_json
end

get "/api/smoke/run/:run_id/image" do
  content_type :json

  Run.find(params[:run_id]).builds.includes(:results => [ :result_bugs ]).all.to_json
end

get "/api/smoke/run/:run_id/image/:image_id" do
  content_type :json

  Build.includes(:results => [ :result_bugs ]).find(params[:image_id]).to_json
end

get "/api/smoke/run/:run_id/image/:image_id/result" do
  content_type :json

  Build.find(params[:image_id]).results.includes(:result_bugs, :result_logs, :bugs).all.to_json
end


get "/api/smoke/run/:run_id/image/:image_id/result/:result_id" do
  content_type :json

  Result.includes(:result_bugs).find(params[:result_id]).to_json
end

get "/api/help" do

  haml :api_help
end


