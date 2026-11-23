# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def up
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest
      t.datetime :email_verified_at
      t.string :reset_token_digest
      t.datetime :reset_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_token_digest, unique: true

    execute <<~SQL.squish
      INSERT INTO users (email, created_at, updated_at)
      SELECT DISTINCT LOWER(TRIM(email)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM (
        SELECT email FROM letters
        UNION
        SELECT email FROM session_tokens
      ) AS existing_emails
      WHERE email IS NOT NULL AND TRIM(email) <> ''
      ON CONFLICT (email) DO NOTHING
    SQL
  end

  def down
    drop_table :users
  end
end
