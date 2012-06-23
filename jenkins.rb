require './simple_http.rb'


$conf = YAML::load(File.open('config/jenkins.yml'))

puts "Using instance: #{$conf['base_url']}"

def get_jenkins_api(loc)
  s = SimpleHTTPRequest.new(loc)
  # Jenkins doesn't set the right content type, so force to JSON
  s.result('json')
end



jobs_top = get_jenkins_api("#{$conf['base_url']}/api/json")
jobs = jobs_top['jobs']

jobs.each do |job|
  name = job['name']
  url  = job['url']

  case name
  when /-bootspeed-/
    # Bootspeed tests
    #puts "Bootspeed test, name: #{name}"

  when /-upgrade-/
    # Upgrade tests
    #puts "Upgrade test, name: #{name}"

  when /^(lucid|natty|oneiric|precise|quantal)-(desktop|server|alternate|core)/
  #when /^(quantal)-(desktop|server|alternate|core)/
  #when /^(quantal)-(core)/

    # Smoke tests
    puts "Smoke test, name: #{name}"
    flavor = 'ubuntu'
    if name.match /(.*)-(.*)-ec2.*/
      if name.match /.*-daily$/
        b = name.scan(/(.*)-(.*)/).first
        release = b[0]
        variant = b[1]
        arch    = "ec2"
        # XXX; need to look inside job for the rest of the info
        # ec2 do not seem to be part of smoke testing anymore
        # matrixes reporting: https://jenkins.qa.ubuntu.com/job/lucid-server-ec2/2/testReport/api/json
      end

    else
      if name.match /(.*)-(.*)-(.*)_(.*)/
        b = name.scan(/(.*)-(.*)-(.*)_(.*)/).first
        release = b[0]
        variant = b[1]
        arch    = b[2]
        name = b[3]
      elsif name.match /(.*)-(.*)-(.*)/
        # quantal-core-amd64, quantal-core-armhf and quantal-core-i386 are 
        # parsed here
        b = name.scan(/(.*)-(.*)-(.*)/).first
        release = b[0]
        variant = b[1]
        arch = b[2]
        name = "default_test"
      end

      puts "Relase: #{release}, Variant: #{variant}, arch: #{arch}, name: #{name}"

      puts "DEBUG: fetching job from #{url}/api/json"
      job_info = get_jenkins_api("#{url}/api/json")
      builds = job_info['builds']
      builds.sort{ |x,y| y['number'].to_i <=> x['number'].to_i }.each do |build|
        build_number = build['number']
        build_url = build['url']
        build_info = get_jenkins_api("#{build_url}/api/json")
        building = build_info['building']
        build_desc = build_info['description']
        # Jenkins multiplies a unix timestamp by a factor of 1000 for some
        # reason.
        build_date = Time.at(build_info['timestamp']/1000).to_datetime

        # Skip this jenkins "build" if it hasn't finished yet
        next if building

        # Extract build_no and bug from build_desc
        #
        # Our preferred source for the build_no is the mediainfo
        # artifact. If that fails, try to find a build_no in the
        # description of the build.
        # If all else fails, make one up based on the run date.
        lp_bugs = []
        build_no = nil

        # Try to extract build_no from mediainfo artifact
        req = SimpleHTTPRequest.new("#{build_url}/artifact/media_info")
        media_info = req.result('text')
        unless media_info.nil?
          s = media_info.scan(/^.*\((.+)\)$/).first
          build_no = s[0]
        end

        if not build_desc.nil?
          b = build_desc.split(/(\s+|,)/)
          b.each do |s|
            s.strip!
            if s.match(/^[0-9]{8}(\.[0-9]+)?$/) and build_no.nil?
              # It's a build number
              build_no = "#{s} ?"
            elsif s.match(/^LP:#[0-9]+$/)
              # It's an LP bug; strip the "LP:#" prefix and add it
              puts "lp_bug:#{s}, [#{s[4..-1]}]"
              lp_bugs << s[4..-1]
            end
          end
        end

        if(variant == "core")
          build_no = build_date.strftime("%Y%m%d") if build_no.nil?
        else
          build_no = build_date.strftime("%Y%m%d ?") if build_no.nil?
        end


        run = Run.where(:release => release, :flavor => flavor, :build_no => build_no)
        if run.empty?
          run = Run.create!(
            :release => release,
            :flavor => flavor,
            :build_no => build_no
          )
        else
          run = run.first
        end

        build = run.builds.where(
          :variant => variant,
          :arch => arch,
          :flavor => flavor)
        if build.empty?
          build = run.builds.create!(
          :variant => variant,
          :arch => arch,
          :flavor => flavor)
          run.touch
        else
          build = build.first
        end

        puts("build.id = #{build.id}, build_number = #{build_number.to_s}, name = #{name}")
        results = build.results.where(:jenkins_build => build_number.to_s, :name => name) #, :ran_at => build_date)

        # We do assume that the builds are in order with newest on top. That being
        # the case, we can safely assume that if we find the current result,
        # there is no point in going any further.
        break unless results.empty?

        fail_count = 0
        skip_count = 0
        pass_count = 0
        total_count = 0
        build_info['actions'].each do |a|
          next if a['totalCount'].nil?
          fail_count = a['failCount']
          skip_count = a['skipCount']
          total_count = a['totalCount']
          pass_count = total_count - fail_count - skip_count
        end

        result = build.results.create!(
          :name => name,
          :ran_at => build_date,
          :jenkins_build => build_number.to_s,
          :jenkins_url => build_url,
          :fail_count => fail_count,
          :skip_count => skip_count,
          :pass_count => pass_count,
          :total_count => total_count
        )
        build.touch
        run.touch

        lp_bugs.each do |bug_no|
          bug = Bug.where(:bug_no => bug_no)
          if bug.empty?
            bug = Bug.create!(:bug_no => bug_no)
            result.touch
            build.touch
            run.touch
          else
            bug = bug.first
          end
          result.bugs << bug
          result.save
        end

        build_info['artifacts'].each do |a|
          dir = "public/logs/#{result.id}"
          path = "#{dir}/#{a['fileName']}"
          artifact_url = "#{build_url}/artifact/#{a['relativePath']}"

          # Create directory if it doesn't exist
          Dir.mkdir('public/logs') unless File.exists?('public/logs')
          Dir.mkdir(dir) unless File.exists?(dir)

          log = result.result_logs.create!(
            :display_name => a['relativePath'],
            :remote_url => artifact_url,
            :path => path
          )
          puts "Pulling artifact from: #{artifact_url}"
          # XXX: temporary commenting out
          #req = SimpleHTTPRequest.new(artifact_url)
          #req.download(path)
          result.touch
          build.touch
          run.touch
        end
      end
    end

  when /^sru-kernel/
    # Kernel SRU tests
    #puts "Kernel SRU test, name: #{name}"

  else
    # Unknown test
    #puts "Unknown test, name: #{name}"
  end
end
