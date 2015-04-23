class CreateBackupJobStats < ActiveRecord::Migration
  def self.up
    create_table :backup_job_stats do |t|
      t.integer :backup_job_id
      t.integer :inodes
      t.integer :n_reg
      t.integer :n_dir
      t.integer :n_lnk
      t.integer :n_spc
      t.integer :n_cre
      t.integer :n_xfr
      t.integer :current_size, :limit => 8
      t.integer :xfr_size, :limit => 8
      t.integer :list_size, :limit => 8
      t.float :list_time
      t.integer :net_sent, :limit => 8
      t.integer :net_recv, :limit => 8

      t.timestamps

    end
    add_index :backup_job_stats, :backup_job_id
  end

  def self.down
    drop_table :backup_job_stats
  end
end
