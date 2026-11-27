# frozen_string_literal: true

class CreateInspirations < ActiveRecord::Migration[8.1]
  def change
    create_table :inspirations do |t|
      t.references :inspiration_category, null: false, foreign_key: true
      t.string :slug, null: false
      t.jsonb :text, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :inspirations, :slug, unique: true
    add_index :inspirations, [ :inspiration_category_id, :position ]
    add_index :inspirations, [ :active, :position ]
  end
end
