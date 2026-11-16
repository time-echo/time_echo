# frozen_string_literal: true

class LetterPolicy
  attr_reader :user_email, :letter

  def initialize(user_email, letter)
    @user_email = user_email
    @letter = letter
  end

  def show?
    owner?
  end

  def archive?
    owner?
  end

  def restore?
    owner?
  end

  def destroy?
    owner?
  end

  alias_method :delete?, :destroy?

  private

  def owner?
    return false if user_email.blank? || letter&.email.blank?

    normalized_user = user_email.to_s.strip.downcase
    normalized_owner = letter.email.to_s.strip.downcase

    return false unless normalized_user.bytesize == normalized_owner.bytesize

    Rack::Utils.secure_compare(normalized_owner, normalized_user)
  end
end
