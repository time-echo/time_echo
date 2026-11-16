# frozen_string_literal: true

class AddStampIdToLetters < ActiveRecord::Migration[8.1]
  def change
    add_reference :letters, :stamp, foreign_key: { on_delete: :restrict }, index: true
  end
end
