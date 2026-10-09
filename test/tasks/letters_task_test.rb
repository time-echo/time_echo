require "test_helper"
require "rake"

class LettersTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("letters:deliver")
  end

  test "letters:deliver task dispatches due pending letters" do
    pending_letter = Letter.new(
      title: "Due Letter",
      email: "due@example.com",
      content: "Hello from yesterday!",
      scheduled_at: 1.day.ago,
      timezone: "America/Bogota",
      status: "pending"
    )
    pending_letter.save!(validate: false)

    Rake::Task["letters:deliver"].reenable
    Rake::Task["letters:deliver"].invoke

    pending_letter.reload
    assert_equal "queued", pending_letter.status
  end
end
