# frozen_string_literal: true

class CreateStampCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :stamp_categories do |t|
      t.string :slug, null: false
      t.jsonb :name, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :stamp_categories, :slug, unique: true
    add_index :stamp_categories, :position
  end
end
