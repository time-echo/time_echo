# frozen_string_literal: true

require "test_helper"

class UserTimelineQueryTest < ActiveSupport::TestCase
  test "filters by archived status" do
    query = UserTimelineQuery.new("test@example.com", Letter.all, status: "archived")
    sql = query.call.to_sql

    assert_includes sql, %("status" = 'archived')
    assert_includes sql, %("email" = 'test@example.com')
  end

  test "filters by delivered status" do
    query = UserTimelineQuery.new("test@example.com", Letter.all, status: "delivered")
    sql = query.call.to_sql

    assert_includes sql, %("status" = 'delivered')
    assert_includes sql, %("email" = 'test@example.com')
  end

  test "filters by scheduled status" do
    query = UserTimelineQuery.new("test@example.com", Letter.all, status: "scheduled")
    sql = query.call.to_sql

    assert_includes sql, %("status" = 'pending')
    assert_includes sql, "scheduled_at"
  end

  test "defaults to active letters ordered by scheduled_at" do
    query = UserTimelineQuery.new("test@example.com", Letter.all)
    sql = query.call.to_sql

    assert_includes sql, %("status" != 'archived')
    assert_includes sql, %("email" = 'test@example.com')
    assert_includes sql, %("scheduled_at" ASC)
  end
end
