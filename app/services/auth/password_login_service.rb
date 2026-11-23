# frozen_string_literal: true

require "bcrypt"

module Auth
  class PasswordLoginService
    def self.call(email:, password:)
      new(email: email, password: password).call
    end

    def self.dummy_password_digest
      @dummy_password_digest ||= BCrypt::Password.create("timeecho-dummy-timing-guard", cost: BCrypt::Engine.cost)
    end

    def initialize(email:, password:)
      @email = email.to_s.strip.downcase
      @password = password.to_s
    end

    def call
      user = User.find_by(email: @email)

      if user.nil? || !user.has_password?
        BCrypt::Password.new(self.class.dummy_password_digest) == @password
        return invalid_credentials_result
      end

      unless user.authenticate(@password)
        return invalid_credentials_result
      end

      Auth::IssueSessionService.call(user: user, auth_method: "password", is_new_user: false)
    end

    Result = ServiceResult

    private

    def invalid_credentials_result
      ServiceResult.failure(
        :invalid_credentials,
        message: I18n.t("flash.invalid_credentials")
      )
    end
  end
end
