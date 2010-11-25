class CreateSHDMNavigationIndices < ActiveRecord::Migration
  def self.up
    create_table :shdm_navigation_indices do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :shdm_navigation_indices
  end
end
