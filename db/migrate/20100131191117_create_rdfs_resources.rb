class CreateRDFSResources < ActiveRecord::Migration
  def self.up
    create_table :rdfs_resources do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :rdfs_resources
  end
end
