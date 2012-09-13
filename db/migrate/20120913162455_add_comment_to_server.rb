class AddCommentToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :comment, :string
  end

  def self.down
    remove_column :servers, :comment
  end
end
