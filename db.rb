

class ResultLog < ActiveRecord::Base
  belongs_to :log, :polymorphic => true
end


class Bug < ActiveRecord::Base
  validates_presence_of   :bug_no
  validates_uniqueness_of :bug_no
end


class Run < ActiveRecord::Base
  has_many    :builds

  def stats
    c = {}
    c[:pass]  = 0
    c[:fail]  = 0
    c[:skip]  = 0
    c[:total] = 0

    builds_pass = 0
    builds_total = 0

    builds.each do |b|
      s = b.stats
      c.each { |k,v| c[k] += s[k] }
      builds_pass += s[:pass_rate]
      builds_total += 1
    end

    c[:pass_rate] = (builds_total == 0) ? 0.0 : builds_pass.to_f / builds_total.to_f

    return c
  end

  def bug_count
    c = 0
    builds.each do |b|
      c += b.bug_count       
    end

    return c    
  end

  def as_json(options={})
    super(
      :methods => [ :stats, :bug_count ],
      :include => { :builds => { :only => [ :id ] } }
    )
  end

end


class Build < ActiveRecord::Base
  belongs_to  :run
  has_many    :results

  validates_presence_of :run
  validates_associated  :run

  def stats
    c = {}
    c[:pass]  = 0
    c[:fail]  = 0
    c[:skip]  = 0
    c[:total] = 0
    c[:pass_rate] = 0

    results.each do |r|
      c[:pass]  += r.pass_count
      c[:fail]  += r.fail_count
      c[:skip]  += r.skip_count
      c[:total] += r.total_count
    end

    c[:pass_rate] = (c[:total] == 0) ? 0.0 : c[:pass].to_f / c[:total].to_f
    return c
  end

  def bug_count
    c = 0
    
    results.each { |r| c += r.bug_count }
    return c
  end

  def as_json(options={})
    super(
      :methods => [ :stats, :bug_count ],
      :include => { :results => { :only => [ :id ] } }
    )
  end
end


class Result < ActiveRecord::Base
  belongs_to  :build
  has_many    :result_logs, :as => :log
  has_many    :result_bugs
  has_many    :bugs, :through => :result_bugs

  validates_presence_of :build
  validates_associated  :build

  def pass_rate
    (total_count == 0) ? 0.0 : pass_count.to_f / total_count.to_f
  end

  def bug_count
    result_bugs.length
  end

  def as_json(options={})
    super(
      :methods => [ :pass_rate, :bug_count ],
      :include => { :bugs => { :only => [ :bug_no, :status ] }, :result_logs => {:only => [ :remote_url, :path ] } }
    )
  end
end


class KernelSru < ActiveRecord::Base
  has_many    :kernel_sru_results
  def stats
    c = {}
    c[:pass]  = 0
    c[:fail]  = 0
    c[:skip]  = 0
    c[:total] = 0
    c[:pass_rate] = 0

    kernel_sru_results.each do |r|
      c[:pass]  += r.pass_count
      c[:fail]  += r.fail_count
      c[:skip]  += r.skip_count
      c[:total] += r.total_count
    end

    c[:pass_rate] = (c[:total] == 0) ? 0.0 : c[:pass].to_f / c[:total].to_f
    return c
  end

  def bug_count
    c = 0

    kernel_sru_results.each { |r| c += r.bug_count }
    return c
  end

  def as_json(options={})
    super(
      :methods => [ :stats, :bug_count ],
      :include => { :kernel_sru_results => { :only => [ :id ] } }
    )
  end
end

class KernelSruResult < ActiveRecord::Base
  belongs_to  :kernel_sru
  has_many    :result_logs, :as => :log
  has_many    :kernel_sru_result_bugs
  has_many    :bugs, :through => :kernel_sru_result_bugs

  validates_presence_of :kernel_sru
  validates_associated  :kernel_sru

  def pass_rate
    (total_count == 0) ? 0.0 : pass_count.to_f / total_count.to_f
  end

  def bug_count
    kernel_sru_result_bugs.length
  end

  def as_json(options={})
    super(
      :methods => [ :pass_rate, :bug_count ],
      :include => { :bugs => { :only => [ :bug_no, :status ] }, :result_logs => {:only => [ :remote_url, :path ] } }
    )
  end
end


class BootspeedRun < ActiveRecord::Base
  has_many    :bootspeed_results
end


class BootspeedResult < ActiveRecord::Base
  belongs_to  :bootspeed_run
  has_many    :result_logs, :as => :log
  has_many    :bootspeed_result_bugs
  has_many    :bugs, :through => :bootspeed_result_bugs

  validates_presence_of :bootspeed_run
  validates_associated  :bootspeed_run
end


class KernelSruResultBug < ActiveRecord::Base
  belongs_to  :kernel_sru_result
  belongs_to  :bug

  validates_uniqueness_of :bug_id, :scope => :kernel_sru_result_id
end


class ResultBug < ActiveRecord::Base 
  belongs_to  :result
  belongs_to  :bug

  validates_uniqueness_of :bug_id, :scope => :result_id
end


class BootspeedResultBug < ActiveRecord::Base 
  belongs_to  :bootspeed_result
  belongs_to  :bug

  validates_uniqueness_of :bug_id, :scope => :bootspeed_result_id
end

