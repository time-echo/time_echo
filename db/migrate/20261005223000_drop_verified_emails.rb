class DropVerifiedEmails < ActiveRecord::Migration[8.1]
  def change
    drop_table :verified_emails do |t|
      t.string :email, null: false
      t.string :token
      t.datetime :token_expires_at
      t.datetime :verified_at

      t.timestamps
    end
  end
end
