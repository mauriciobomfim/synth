class CreateSWUIConcreteWidgets < ActiveRecord::Migration
  def self.up
    create_table :swui_concrete_widgets do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :swui_concrete_widgets
  end
end
