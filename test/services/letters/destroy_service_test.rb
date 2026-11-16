# frozen_string_literal: true

require "test_helper"

class Letters::DestroyServiceTest < ActiveSupport::TestCase
  setup do
    @user = "owner@example.com"
  end

  test "destroys archived letter, dependent records, and tracks analytics and audit log" do
    letter = Letter.new(
      title: "Archived Letter to Delete",
      email: @user,
      content: "Letter to be deleted",
      scheduled_at: 1.year.from_now,
      status: "archived"
    )
    letter.save!(validate: false)

    pred = letter.predictions.create!(category: "city", prediction: "Tokyo")
    snap = letter.create_emotional_snapshot!(happiness_level: 8, anxiety_level: 2, motivation_level: 9)

    events_tracked = []
    original_track = Analytics::TrackEventService.method(:call)
    Analytics::TrackEventService.define_singleton_method(:call) do |event, payload|
      events_tracked << { event: event, payload: payload }
    end

    assert_difference -> { Letter.count } => -1,
                      -> { Prediction.count } => -1,
                      -> { EmotionalSnapshot.count } => -1,
                      -> { AuditLog.for_action("letter.deleted").count } => 1 do
      result = Letters::DestroyService.call(letter.id, @user)
      assert result.success?
      assert_equal letter, result.letter
    end

    assert_not Letter.exists?(letter.id)
    assert_not Prediction.exists?(pred.id)
    assert_not EmotionalSnapshot.exists?(snap.id)

    assert_includes events_tracked.map { |e| e[:event] }, "letter_deleted"
    audit = AuditLog.for_action("letter.deleted").last
    assert_nil audit.auditable
    assert_equal @user, audit.actor_email
    assert_equal letter.id, audit.metadata["letter_id"]
    assert_equal "archived", audit.metadata["status_at_deletion"]
  ensure
    Analytics::TrackEventService.define_singleton_method(:call, original_track.to_proc)
  end

  test "supports deleting via signed_id" do
    letter = Letter.new(
      title: "Archived Letter Signed ID",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.from_now,
      status: "archived"
    )
    letter.save!(validate: false)

    result = Letters::DestroyService.call(letter.signed_id, @user)

    assert result.success?
    assert_not Letter.exists?(letter.id)
  end

  test "returns cannot_delete when letter is pending" do
    letter = Letter.new(
      title: "Pending Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.from_now,
      status: "pending"
    )
    letter.save!(validate: false)

    result = Letters::DestroyService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :cannot_delete, result.error
    assert Letter.exists?(letter.id)
  end

  test "returns cannot_delete when letter is queued" do
    letter = Letter.new(
      title: "Queued Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.from_now,
      status: "queued"
    )
    letter.save!(validate: false)

    result = Letters::DestroyService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :cannot_delete, result.error
    assert Letter.exists?(letter.id)
  end

  test "returns cannot_delete when letter is delivered" do
    letter = Letter.new(
      title: "Delivered Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.ago,
      delivered_at: 1.year.ago,
      status: "delivered"
    )
    letter.save!(validate: false)

    result = Letters::DestroyService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :cannot_delete, result.error
    assert Letter.exists?(letter.id)
  end

  test "returns cannot_delete when letter is failed" do
    letter = Letter.new(
      title: "Failed Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.day.ago,
      status: "failed"
    )
    letter.save!(validate: false)

    result = Letters::DestroyService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :cannot_delete, result.error
    assert Letter.exists?(letter.id)
  end

  test "returns not_found when user does not own the letter" do
    letter = Letter.new(
      title: "Someone Else's Letter",
      email: "stranger@example.com",
      content: "Secret content",
      scheduled_at: 1.year.from_now,
      status: "archived"
    )
    letter.save!(validate: false)

    result = Letters::DestroyService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :not_found, result.error
    assert Letter.exists?(letter.id)
  end

  test "returns not_found when letter does not exist" do
    result = Letters::DestroyService.call(999_999, @user)

    assert_not result.success?
    assert_equal :not_found, result.error
  end
end
