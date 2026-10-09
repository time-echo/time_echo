require "test_helper"

class Letters::DeliverLetterJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def build_queued_letter(overrides = {})
    letter = Letter.new({
      title: "Queued Letter",
      email: "queued@example.com",
      content: "Hello future me!",
      scheduled_at: 1.day.ago,
      timezone: "America/Bogota",
      status: "queued",
      queued_at: 1.minute.ago
    }.merge(overrides))
    letter.save!(validate: false)
    letter
  end

  test "delivers letter successfully and marks it delivered" do
    letter = build_queued_letter

    assert_emails 1 do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_equal "delivered", letter.status
    assert_not_nil letter.delivered_at
  end

  test "is idempotent — skips already delivered letters" do
    letter = build_queued_letter(status: "delivered", delivered_at: 5.minutes.ago)

    assert_emails 0 do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_equal "delivered", letter.status
  end

  test "skips archived letters without delivering" do
    letter = build_queued_letter(status: "archived")

    assert_emails 0 do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_equal "archived", letter.status
  end

  test "marks letter failed and re-raises on non-retryable error" do
    letter = build_queued_letter
    original = LetterMailer.method(:future_letter)

    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise RuntimeError, "permanent SMTP rejection"
    end

    assert_raises(RuntimeError) do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_equal "failed", letter.status
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "re-enqueues on Net::OpenTimeout without marking letter failed" do
    letter = build_queued_letter
    original = LetterMailer.method(:future_letter)

    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise Net::OpenTimeout
    end

    assert_enqueued_with(job: Letters::DeliverLetterJob) do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_not_equal "failed", letter.status,
      "transient errors must not mark the letter failed during retry window"
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "re-enqueues on SocketError without marking letter failed" do
    letter = build_queued_letter
    original = LetterMailer.method(:future_letter)

    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise SocketError, "Failed to open TCP connection to smtp.example.com"
    end

    assert_enqueued_with(job: Letters::DeliverLetterJob) do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_not_equal "failed", letter.status
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "marks letter failed on non-transient StandardError" do
    letter = build_queued_letter
    original = LetterMailer.method(:future_letter)

    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise StandardError, "auth failure"
    end

    assert_raises(StandardError) do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end

    letter.reload
    assert_equal "failed", letter.status
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "skips execution gracefully when letter record is not found" do
    assert_nothing_raised do
      assert_emails 0 do
        Letters::DeliverLetterJob.perform_now(-1)
      end
    end
  end

  test "discards job when ActiveJob::DeserializationError is raised" do
    letter = build_queued_letter
    original = Letter.method(:find)
    Letter.define_singleton_method(:find) do |*|
      begin
        raise StandardError, "missing record"
      rescue StandardError
        raise ActiveJob::DeserializationError
      end
    end

    assert_nothing_raised do
      Letters::DeliverLetterJob.perform_now(letter.id)
    end
  ensure
    Letter.define_singleton_method(:find, original.to_proc)
  end

  test "marks letter failed and tracks event when retries are exhausted on transient error" do
    letter = build_queued_letter
    job = Letters::DeliverLetterJob.new(letter.id)
    job.executions = 5
    job.exception_executions[Letters::DeliverLetterJob::TRANSIENT_ERRORS.to_s] = 5

    original = LetterMailer.method(:future_letter)
    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise Net::OpenTimeout, "execution timed out"
    end

    job.perform_now

    letter.reload
    assert_equal "failed", letter.status
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end
end
