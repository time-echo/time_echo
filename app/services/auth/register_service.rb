# frozen_string_literal: true

module Auth
  class RegisterService
    def self.call(email:, password:, password_confirmation: nil, locale: nil)
      new(
        email: email,
        password: password,
        password_confirmation: password_confirmation,
        locale: locale
      ).call
    end

    def initialize(email:, password:, password_confirmation: nil, locale: nil)
      @email = email.to_s.strip.downcase
      @password = password.to_s
      @password_confirmation = password_confirmation
      @locale = locale
    end

    def call
      if @password.blank?
        user = User.new(email: @email)
        user.errors.add(:password, :blank)
        return ServiceResult.failure(:invalid, errors: user.errors)
      end

      existing_user = User.find_by(email: @email)
      if existing_user.present?
        if existing_user.has_password?
          user = User.new(email: @email)
          user.errors.add(:email, :taken)
          return ServiceResult.failure(:invalid, errors: user.errors)
        end

        Auth::MagicLinkService.generate_and_send(@email, locale: @locale)
        return ServiceResult.success(
          {
            requires_email_verification: true,
            email: @email,
            message: I18n.t("flash.registration_check_email")
          }
        )
      end

      user = User.new(email: @email, password: @password)
      user.password_confirmation = @password_confirmation unless @password_confirmation.nil?

      unless user.save
        return ServiceResult.failure(:invalid, errors: user.errors)
      end

      Auth::IssueSessionService.call(user: user, auth_method: "password", is_new_user: true)
    end

    Result = ServiceResult
  end
end
