class Setup < ActiveRecord::Migration
  def self.up

    create_table :result_logs do |t|
      t.integer     :log_id
      t.string      :log_type

      t.string      :mime_type
      t.string      :display_name
      t.text        :path
      t.text        :remote_url
      t.timestamps
    end


    create_table :bugs do |t|
      t.string      :bug_no
      t.string      :status
      t.timestamps
    end

    add_index :bugs, :bug_no, :unique => true


    create_table :runs do |t|
      t.string      :build_no
      t.string      :release
      t.string      :flavor
      t.text        :sync_data
      t.integer     :test_type
      t.datetime    :ran_at
      t.timestamps
    end

    add_index :runs, :release, :unique => false
    add_index :runs, :build_no, :unique => false


    create_table :builds do |t|
      t.references  :run
      t.string      :name # ???
      t.string      :flavor
      t.string      :variant
      t.string      :arch
      t.text        :sync_data
      t.timestamps
    end

    add_foreign_key :builds, :runs, :dependent => :delete


    create_table :results do |t|
      t.references  :build
      t.references  :log, :polymorphic => true

      t.string      :jenkins_build
      t.string      :jenkins_url

      t.string      :name
      t.string      :lp_bug
      t.integer     :fail_count
      t.integer     :skip_count
      t.integer     :pass_count
      t.integer     :total_count
      t.datetime    :ran_at
      t.timestamps
    end

    add_foreign_key :results, :builds, :dependent => :delete


    create_table :result_bugs do |t|
      t.references  :result
      t.references  :bug
    end

    add_foreign_key :result_bugs, :results, :dependent => :delete
    add_foreign_key :result_bugs, :bugs, :dependent => :delete
    add_index :result_bugs, [:result_id, :bug_id], :unique => true


    create_table :bootspeed_runs do |t|
      t.string      :variant
      t.string      :arch
      t.string      :flavor
      t.string      :release
      t.string      :machine
      t.text        :sync_data
      t.timestamps
    end
 

    create_table :bootspeed_results do |t|
      t.references  :bootspeed_run
      t.references  :log, :polymorphic => true

      t.string      :build_no
      t.float       :boot_time
      t.float       :kernel_init_time
      t.float       :kernel_time
      t.float       :plumbing_time
      t.float       :x_time
      t.float       :desktop_time
      t.text        :sync_data
      t.datetime    :ran_at
      t.timestamps
    end

    add_foreign_key :bootspeed_results, :bootspeed_runs, :dependent => :delete


    create_table :bootspeed_result_bugs do |t|
      t.references  :bootspeed_result
      t.references  :bug
    end

    add_foreign_key :bootspeed_result_bugs, :bootspeed_results, :dependent => :delete
    add_foreign_key :bootspeed_result_bugs, :bugs, :dependent => :delete
    add_index :bootspeed_result_bugs, [:bootspeed_result_id, :bug_id], :unique => true
  end

  

  def self.down
    drop_table :result_bugs
    drop_table :bootspeed_result_bugs
    drop_table :bugs
    drop_table :result_logs
    drop_table :results
    drop_table :builds
    drop_table :runs
    drop_table :bootspeed_results
    drop_table :bootspeed_runs
  end
end
