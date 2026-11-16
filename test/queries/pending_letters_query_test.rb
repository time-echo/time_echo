# frozen_string_literal: true

require "test_helper"

class PendingLettersQueryTest < ActiveSupport::TestCase
  test "generates pending letters query with skip locked" do
    time = Time.zone.parse("2026-11-15 12:00:00 UTC")
    query = PendingLettersQuery.new(Letter.all, time: time)
    sql = query.call.to_sql

    assert_includes sql, %("status" = 'pending')
    assert_includes sql, "FOR UPDATE SKIP LOCKED"
    assert_includes sql, %("scheduled_at" ASC)
  end
end
