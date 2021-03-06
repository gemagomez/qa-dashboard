# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120530073955) do

  create_table "bootspeed_result_bugs", :force => true do |t|
    t.integer "bootspeed_result_id"
    t.integer "bug_id"
  end

  add_index "bootspeed_result_bugs", ["bootspeed_result_id", "bug_id"], :name => "index_bootspeed_result_bugs_on_bootspeed_result_id_and_bug_id", :unique => true

  create_table "bootspeed_results", :force => true do |t|
    t.integer  "bootspeed_run_id"
    t.integer  "log_id"
    t.string   "log_type"
    t.string   "build_no"
    t.float    "boot_time"
    t.float    "kernel_init_time"
    t.float    "kernel_time"
    t.float    "plumbing_time"
    t.float    "x_time"
    t.float    "desktop_time"
    t.text     "sync_data"
    t.datetime "ran_at"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "bootspeed_runs", :force => true do |t|
    t.string   "variant"
    t.string   "arch"
    t.string   "flavor"
    t.string   "release"
    t.string   "machine"
    t.text     "sync_data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "bugs", :force => true do |t|
    t.string   "bug_no"
    t.string   "status"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "bugs", ["bug_no"], :name => "index_bugs_on_bug_no", :unique => true

  create_table "builds", :force => true do |t|
    t.integer  "run_id"
    t.string   "name"
    t.string   "flavor"
    t.string   "variant"
    t.string   "arch"
    t.text     "sync_data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "result_bugs", :force => true do |t|
    t.integer "result_id"
    t.integer "bug_id"
  end

  add_index "result_bugs", ["result_id", "bug_id"], :name => "index_result_bugs_on_result_id_and_bug_id", :unique => true

  create_table "result_logs", :force => true do |t|
    t.integer  "log_id"
    t.string   "log_type"
    t.string   "mime_type"
    t.string   "display_name"
    t.text     "path"
    t.text     "remote_url"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "results", :force => true do |t|
    t.integer  "build_id"
    t.integer  "log_id"
    t.string   "log_type"
    t.string   "jenkins_build"
    t.string   "jenkins_url"
    t.string   "name"
    t.string   "lp_bug"
    t.integer  "fail_count"
    t.integer  "skip_count"
    t.integer  "pass_count"
    t.integer  "total_count"
    t.datetime "ran_at"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "runs", :force => true do |t|
    t.string   "build_no"
    t.string   "release"
    t.string   "flavor"
    t.text     "sync_data"
    t.integer  "test_type"
    t.datetime "ran_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "runs", ["build_no"], :name => "index_runs_on_build_no"
  add_index "runs", ["flavor"], :name => "index_runs_on_flavor"
  add_index "runs", ["release"], :name => "index_runs_on_release"

  add_foreign_key "bootspeed_result_bugs", "bootspeed_results", :name => "bootspeed_result_bugs_bootspeed_result_id_fk", :dependent => :delete
  add_foreign_key "bootspeed_result_bugs", "bugs", :name => "bootspeed_result_bugs_bug_id_fk", :dependent => :delete

  add_foreign_key "bootspeed_results", "bootspeed_runs", :name => "bootspeed_results_bootspeed_run_id_fk", :dependent => :delete

  add_foreign_key "builds", "runs", :name => "builds_run_id_fk", :dependent => :delete

  add_foreign_key "result_bugs", "bugs", :name => "result_bugs_bug_id_fk", :dependent => :delete
  add_foreign_key "result_bugs", "results", :name => "result_bugs_result_id_fk", :dependent => :delete

  add_foreign_key "results", "builds", :name => "results_build_id_fk", :dependent => :delete

end
