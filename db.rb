class Job < ActiveRecord::Base
  self.table_name = "job"
  self.primary_key = "jobid"

  has_many :results
end

class Result < ActiveRecord::Base
  self.table_name = "result"
  self.primary_key = "rowid"

  belongs_to :job, :inverse_of => :results, :foreign_key => "jobid"

  def date
    return (self[:date] != nil) ? self[:date].strftime("%d/%m/%Y - %H:%M") : nil
  end

end
