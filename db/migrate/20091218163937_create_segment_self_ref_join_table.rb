class CreateSegmentSelfRefJoinTable < ActiveRecord::Migration
  def self.up
    create_table :aligned_segments, :id => false do |t|
      t.integer :segment_id, :null => false
      t.integer :aligned_segment_id, :null => false
    end
  end

  def self.down
    drop_table :aligned_segments
  end
end
