class CreateSHDMOperations < ActiveRecord::Migration
  def self.up
    create_table :shdm_operations do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :shdm_operations
  end
end
