class AddTimingToBackupJobStats < ActiveRecord::Migration
  def change
    add_column :backup_job_stats, :time_other, :integer
    add_column :backup_job_stats, :time_snap, :integer
    add_column :backup_job_stats, :time_rsync, :integer
  end
end
