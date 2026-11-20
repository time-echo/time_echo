# frozen_string_literal: true

require "test_helper"

class Letters::ArchiveServiceTest < ActiveSupport::TestCase
  setup do
    @user = "owner@example.com"
  end

  test "archives letter and tracks analytics event when authorized" do
    letter = Letter.new(
      title: "Letter to Archive",
      email: @user,
      content: "Archival content",
      scheduled_at: 1.year.from_now,
      status: "pending"
    )
    letter.save!(validate: false)

    events_tracked = []
    original_track = Analytics::TrackEventService.method(:call)
    Analytics::TrackEventService.define_singleton_method(:call) do |event, payload|
      events_tracked << { event: event, payload: payload }
    end

    result = Letters::ArchiveService.call(letter.id, @user)

    assert result.success?
    assert_equal letter, result.letter
    assert_equal "archived", letter.reload.status
    assert_includes events_tracked.map { |e| e[:event] }, "letter_archived"
  ensure
    Analytics::TrackEventService.define_singleton_method(:call, original_track.to_proc)
  end

  test "supports archiving via signed_id" do
    letter = Letter.new(
      title: "Letter to Archive",
      email: @user,
      content: "Archival content",
      scheduled_at: 1.year.from_now,
      status: "pending"
    )
    letter.save!(validate: false)

    result = Letters::ArchiveService.call(letter.signed_id, @user)

    assert result.success?
    assert_equal "archived", letter.reload.status
  end

  test "returns not_found when user does not own the letter" do
    letter = Letter.new(
      title: "Other's Letter",
      email: "other@example.com",
      content: "Secret content",
      scheduled_at: 1.year.from_now,
      status: "pending"
    )
    letter.save!(validate: false)

    result = Letters::ArchiveService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :not_found, result.error
    assert_equal "pending", letter.reload.status
  end

  test "archives delivered letter when authorized" do
    letter = Letter.new(
      title: "Delivered Letter",
      email: @user,
      content: "Delivered content",
      scheduled_at: 1.year.ago,
      delivered_at: 1.year.ago,
      status: "delivered"
    )
    letter.save!(validate: false)

    result = Letters::ArchiveService.call(letter.id, @user)

    assert result.success?
    assert_equal "archived", letter.reload.status
  end

  test "returns cannot_archive_delivered when letter is already archived" do
    letter = Letter.new(
      title: "Already Archived Letter",
      email: @user,
      content: "Archived content",
      scheduled_at: 1.year.ago,
      status: "archived"
    )
    letter.save!(validate: false)

    result = Letters::ArchiveService.call(letter.id, @user)

    assert_not result.success?
    assert_equal :cannot_archive_delivered, result.error
    assert_equal "archived", letter.reload.status
  end

  test "returns not_found when letter does not exist" do
    result = Letters::ArchiveService.call(999_999, @user)

    assert_not result.success?
    assert_equal :not_found, result.error
  end
end
