# frozen_string_literal: true

require "test_helper"

class Letters::RestoreServiceTest < ActiveSupport::TestCase
  setup do
    @user = "owner@example.com"
  end

  test "restores an archived pending letter back to pending" do
    letter = Letter.new(
      title: "Archived Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.from_now,
      status: "archived"
    )
    letter.save!(validate: false)

    events_tracked = []
    original_track = Analytics::TrackEventService.method(:call)
    Analytics::TrackEventService.define_singleton_method(:call) do |event, payload|
      events_tracked << { event: event, payload: payload }
    end

    result = Letters::RestoreService.call(letter.id, @user)

    assert result.success?
    assert_equal "pending", letter.reload.status
    assert_includes events_tracked.map { |e| e[:event] }, "letter_restored"
  ensure
    Analytics::TrackEventService.define_singleton_method(:call, original_track.to_proc)
  end

  test "restores an archived delivered letter back to delivered" do
    letter = Letter.new(
      title: "Archived Delivered Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.ago,
      delivered_at: 1.year.ago,
      status: "archived"
    )
    letter.save!(validate: false)

    result = Letters::RestoreService.call(letter.id, @user)

    assert result.success?
    assert_equal "delivered", letter.reload.status
  end

  test "returns cannot_restore when letter is not archived" do
    letter = Letter.new(
      title: "Delivered Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.ago,
      delivered_at: 1.year.ago,
      status: "delivered"
    )
    letter.save!(validate: false)

    result = Letters::RestoreService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :cannot_restore, result.error
    assert_equal "delivered", letter.reload.status
  end

  test "supports restoration via signed_id" do
    letter = Letter.new(
      title: "Signed ID Letter",
      email: @user,
      content: "Content",
      scheduled_at: 1.year.from_now,
      status: "archived"
    )
    letter.save!(validate: false)

    result = Letters::RestoreService.call(letter.signed_id, @user)

    assert result.success?
    assert_equal "pending", letter.reload.status
  end

  test "returns not_found when non-owner attempts to restore" do
    letter = Letter.new(
      title: "Someone Else's Letter",
      email: "stranger@example.com",
      content: "Content",
      scheduled_at: 1.year.from_now,
      status: "archived"
    )
    letter.save!(validate: false)

    result = Letters::RestoreService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :not_found, result.error
    assert_equal "archived", letter.reload.status
  end

  test "returns not_found when letter does not exist" do
    result = Letters::RestoreService.call(999_999, @user)

    assert_not result.success?
    assert_equal :not_found, result.error
  end
end
