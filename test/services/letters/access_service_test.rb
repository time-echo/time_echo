require "test_helper"

class Letters::AccessServiceTest < ActiveSupport::TestCase
  setup do
    @user = "user@example.com"
  end

  test "returns not_found for missing letter" do
    result = Letters::AccessService.call(999, @user)
    assert_not result.success?
    assert_equal :not_found, result.error
  end

  test "returns success for owned letter" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.ago, status: "delivered")
    letter.save!(validate: false)
    result = Letters::AccessService.call(letter.id, @user)
    assert result.success?
    assert_equal letter, result.letter
    assert_not result.countdown?
  end

  test "returns countdown for pending letter" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.from_now, status: "pending")
    letter.save!(validate: false)
    result = Letters::AccessService.call(letter.id, @user)
    assert result.success?
    assert result.countdown?
  end

  test "returns not_found for letter found but policy denies" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.ago, status: "delivered")
    letter.save!(validate: false)

    original_show = LetterPolicy.instance_method(:show?)
    LetterPolicy.class_eval do
      alias_method :original_show?, :show?
      define_method(:show?) { |*| false }
    end

    result = Letters::AccessService.call(letter.id, @user)
    assert_not result.success?
    assert_equal :not_found, result.error
  ensure
    LetterPolicy.class_eval do
      alias_method :show?, :original_show?
      remove_method :original_show?
    end
  end

  test "returns success for owned letter accessed via signed_id" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.ago, status: "delivered")
    letter.save!(validate: false)
    result = Letters::AccessService.call(letter.signed_id, @user)
    assert result.success?
    assert_equal letter, result.letter
  end

  test "returns not_found for signed_id when user is not owner" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.ago, status: "delivered")
    letter.save!(validate: false)
    result = Letters::AccessService.call(letter.signed_id, "other@example.com")
    assert_not result.success?
    assert_equal :not_found, result.error
  end

  test "returns not_found for signed_id when user is nil" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.ago, status: "delivered")
    letter.save!(validate: false)
    result = Letters::AccessService.call(letter.signed_id, nil)
    assert_not result.success?
    assert_equal :not_found, result.error
  end

  test "returns not_found for archived letter" do
    letter = Letter.new(title: "Test", email: @user, content: "Hello", deliver_at: 1.day.ago, status: "archived")
    letter.save!(validate: false)
    result = Letters::AccessService.call(letter.id, @user)
    assert_not result.success?
    assert_equal :not_found, result.error
  end
end
