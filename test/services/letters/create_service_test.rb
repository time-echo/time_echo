require "test_helper"

class Letters::CreateServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @valid_params = {
      title: "My Future Self",
      email: "author@example.com",
      content: "Hello future me! I am writing this letter to document where I stand today and my goals.",
      deliver_at: 1.year.from_now,
      happiness_level: 8,
      anxiety_level: 2,
      motivation_level: 9,
      prediction_city: "Madrid"
    }
  end

  test "creates a letter and sends stamped confirmation email" do
    assert_enqueued_emails 1 do
      result = Letters::CreateService.call(
        params: @valid_params,
        current_user_email: nil
      )
      assert result.success?
      assert_equal "author@example.com", result.letter.email
    end
  end

  test "creates a letter for signed-in user and sends stamped confirmation" do
    assert_enqueued_emails 1 do
      result = Letters::CreateService.call(
        params: @valid_params,
        current_user_email: "signed_in@example.com"
      )
      assert result.success?
      assert_equal "signed_in@example.com", result.letter.email
    end
  end

  test "returns failure when params are invalid" do
    invalid_params = @valid_params.merge(title: "")
    result = Letters::CreateService.call(
      params: invalid_params,
      current_user_email: "signed_in@example.com"
    )
    assert_not result.success?
    assert result.errors.added?(:title, :blank)
  end
end
