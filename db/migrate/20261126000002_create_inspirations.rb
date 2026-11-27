# frozen_string_literal: true

class CreateInspirations < ActiveRecord::Migration[8.1]
  def change
    create_table :inspirations do |t|
      t.string :slug, null: false
      t.jsonb :text, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :inspirations, :slug, unique: true
    add_index :inspirations, [ :active, :position ]
  end
end
