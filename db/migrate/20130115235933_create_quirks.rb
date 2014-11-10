class CreateQuirks < ActiveRecord::Migration
  def self.up
    create_table :quirks do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :quirks
  end

end
