require "test_helper"

class Letters::UpdatePredictionsServiceTest < ActiveSupport::TestCase
  setup do
    @letter = Letter.new(
      title: "Test",
      email: "user@example.com",
      content: "Hello",
      deliver_at: 1.day.ago,
      status: "delivered"
    )
    @letter.save!(validate: false)
    @prediction = @letter.predictions.create!(category: "city", prediction: "Bogotá")
  end

  test "updates predictions successfully" do
    result = Letters::UpdatePredictionsService.call(
      @letter.id,
      { predictions: { @prediction.id.to_s => { reality: "Madrid", matched: "1" } } },
      @letter.email
    )
    assert result.success?
    @prediction.reload
    assert_equal "Madrid", @prediction.reality
    assert @prediction.matched?
  end

  test "returns not_found for nil or pending letter" do
    result = Letters::UpdatePredictionsService.call(999, {}, @letter.email)
    assert_not result.success?
    assert_equal :not_found, result.error

    pending_letter = Letter.new(
      title: "Pending",
      email: "user@example.com",
      content: "Hello",
      deliver_at: 1.day.from_now,
      status: "pending"
    )
    pending_letter.save!(validate: false)

    pending_result = Letters::UpdatePredictionsService.call(pending_letter.id, {}, pending_letter.email)
    assert_not pending_result.success?
    assert_equal :not_found, pending_result.error
  end

  test "returns unauthorized when policy denies" do
    original_show = LetterPolicy.instance_method(:show?)
    LetterPolicy.class_eval do
      alias_method :original_show?, :show?
      define_method(:show?) { |*| false }
    end

    result = Letters::UpdatePredictionsService.call(
      @letter.id,
      { predictions: { @prediction.id.to_s => { reality: "Madrid", matched: "1" } } },
      @letter.email
    )
    assert_not result.success?
    assert_equal :unauthorized, result.error
  ensure
    LetterPolicy.class_eval do
      alias_method :show?, :original_show?
      remove_method :original_show?
    end
  end

  test "returns invalid when record invalid is raised" do
    original_transaction = Letter.method(:transaction)
    Letter.define_singleton_method(:transaction) do |*args, &block|
      raise ActiveRecord::RecordInvalid.new(Letter.new)
    end

    result = Letters::UpdatePredictionsService.call(
      @letter.id,
      { predictions: { @prediction.id.to_s => { reality: "Madrid", matched: "1" } } },
      @letter.email
    )
    assert_not result.success?
    assert_equal :invalid, result.error
  ensure
    Letter.define_singleton_method(:transaction, original_transaction.to_proc)
  end
end
