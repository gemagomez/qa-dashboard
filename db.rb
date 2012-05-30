

class ResultLog < ActiveRecord::Base
  belongs_to :log, :polymorphic => true
end


class Run < ActiveRecord::Base
  has_many    :builds
end


class Build < ActiveRecord::Base
  belongs_to  :run
  has_many    :results

  validates_presence_of :run
  validates_associated  :run

  def stats
    c[:pass]  = 0
    c[:fail]  = 0
    c[:skip]  = 0
    c[:total] = 0
    c[:pass_rate] = 0

    results.each do |r|
      c[:pass]  += c.pass_count
      c[:fail]  += c.fail_count
      c[:skip]  += c.skip_count
      c[:total] += c.total_count
    end

    c[:pass_rate] = c.pass_count.to_f / c.total_count.to_f
    return c
  end
end


class Result < ActiveRecord::Base
  belongs_to  :build
  has_many    :result_logs, :as => :log
  has_many    :bugs, :through => :result_bugs

  validates_presence_of :build
  validates_associated  :build

  def pass_rate
    pass_count.to_f / total_count.to_f
  end
end


class BootspeedRun < ActiveRecord::Base
  has_many    :bootspeed_results
end


class BootspeedResult < ActiveRecord::Base
  belongs_to  :bootspeed_run
  has_many    :result_logs, :as => :log
  has_many    :bugs, :through => :bootspeed_result_bugs

  validates_presence_of :bootspeed_run
  validates_associated  :bootspeed_run
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

