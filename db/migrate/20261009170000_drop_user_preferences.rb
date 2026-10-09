class DropUserPreferences < ActiveRecord::Migration[8.1]
  def change
    drop_table :user_preferences do |t|
      t.string :email, null: false
      t.datetime :confirmed_at
      t.string :unconfirmed_email

      t.timestamps
    end
  end
end
