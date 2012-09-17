class AddDiskUsedToBackupServers < ActiveRecord::Migration
  def self.up
    remove_column :backup_servers, :disk_free
    add_column :backup_servers, :disk_free, :integer, :limit => 8
    add_column :backup_servers, :disk_used, :integer, :limit => 8
    add_column :backup_servers, :disk_size, :integer, :limit => 8
  end

  def self.down
    remove_column :backup_servers, :disk_used
    remove_column :backup_servers, :disk_size
    remove_column :backup_servers, :disk_free
    add_column :backup_servers, :disk_free, :string
  end
end
