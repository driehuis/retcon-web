class AddRetention2ToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :retention_days, :integer
    add_column :servers, :retention_weeks, :integer
    add_column :servers, :retention_months, :integer
  end

  def self.down
    remove_column :servers, :retention_months
    remove_column :servers, :retention_weeks
    remove_column :servers, :retention_days
  end
end
