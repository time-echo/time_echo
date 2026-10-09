require "test_helper"

class Letters::DispatchPendingServiceTest < ActiveJob::TestCase
  def build_letter(overrides = {})
    letter = Letter.new({
      title: "Test Capsule",
      email: "test@example.com",
      content: "Hello future me!",
      scheduled_at: 1.day.ago,
      timezone: "America/Bogota",
      status: "pending"
    }.merge(overrides))
    letter.save!(validate: false)
    letter
  end

  test "queues due pending letters and enqueues deliver letter jobs" do
    due_letter1 = build_letter(email: "due1@example.com")
    due_letter2 = build_letter(email: "due2@example.com")
    future_letter = build_letter(scheduled_at: 1.month.from_now, email: "future@example.com")

    assert_difference -> { AuditLog.for_action("letter.queued").count } => 2 do
      assert_enqueued_jobs 2, only: Letters::DeliverLetterJob do
        queued_count = Letters::DispatchPendingService.call
        assert_equal 2, queued_count
      end
    end

    due_letter1.reload
    due_letter2.reload
    future_letter.reload

    assert_equal "queued", due_letter1.status
    assert_not_nil due_letter1.queued_at

    assert_equal "queued", due_letter2.status
    assert_not_nil due_letter2.queued_at

    assert_equal "pending", future_letter.status
    assert_nil future_letter.queued_at
  end

  test "does not re-queue already queued, delivered, or failed letters" do
    build_letter(status: "queued", queued_at: 10.minutes.ago)
    build_letter(status: "delivered", delivered_at: 1.day.ago)
    build_letter(status: "failed")

    assert_enqueued_jobs 0 do
      queued_count = Letters::DispatchPendingService.call
      assert_equal 0, queued_count
    end
  end
end
