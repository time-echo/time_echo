# frozen_string_literal: true

class CreateStamps < ActiveRecord::Migration[8.1]
  def change
    create_table :stamps do |t|
      t.references :stamp_category, null: false, foreign_key: true
      t.string :slug, null: false
      t.jsonb :name, null: false, default: {}
      t.text :svg_content, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :stamps, :slug, unique: true
    add_index :stamps, [ :stamp_category_id, :position ]
    add_index :stamps, [ :active, :position ]
  end
end
