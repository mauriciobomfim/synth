class CreateSWUIInterfaces < ActiveRecord::Migration
  def self.up
    create_table :swui_interfaces do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :swui_interfaces
  end
end
