class CreateSHDMNavigationContexts < ActiveRecord::Migration
  def self.up
    create_table :shdm_navigation_contexts do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :shdm_navigation_contexts
  end
end
