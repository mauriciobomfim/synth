class CreateSHDMIndexAttributes < ActiveRecord::Migration
  def self.up
    create_table :shdm_index_attributes do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :shdm_index_attributes
  end
end
