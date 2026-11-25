# frozen_string_literal: true

class CreateIdentitiesAndOauthStates < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email

      t.timestamps
    end

    add_index :identities, [ :provider, :uid ], unique: true
    add_index :identities, [ :user_id, :provider ], unique: true

    create_table :oauth_states do |t|
      t.string :state_digest, null: false
      t.string :provider, null: false
      t.string :code_verifier, null: false
      t.string :purpose, null: false, default: "login"
      t.references :user, null: true, foreign_key: true
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :oauth_states, :state_digest, unique: true
    add_index :oauth_states, :expires_at
  end
end
