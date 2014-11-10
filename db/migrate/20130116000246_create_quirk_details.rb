class CreateQuirkDetails < ActiveRecord::Migration
  def self.up
    create_table :quirk_details do |t|
      t.integer :server_id
      t.integer :quirk_id
      t.string  :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :quirk_details
  end
end
