class ResizeUsageFieldInServer < ActiveRecord::Migration
  def self.up
    change_column :servers, :usage, :integer, :limit => 8
  end
end
