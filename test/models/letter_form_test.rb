require "test_helper"

class LetterFormTest < ActiveSupport::TestCase
  test "valid letter form creates letter, emotional snapshot, and predictions with timezone" do
    params = {
      title: "My Future self",
      email: "test@example.com",
      content: "Hello from the past! I hope this message finds you in great spirits, thriving and healthy.",
      deliver_at: "2027-05-20",
      timezone: "America/Bogota",
      happiness_level: 7,
      anxiety_level: 3,
      motivation_level: 8,
      prediction_city: "Madrid",
      prediction_salary: "$90,000",
      prediction_relationship: "married",
      prediction_career: "Tech Lead",
      prediction_achievement: "run a marathon"
    }

    form = LetterForm.new(params)

    assert form.valid?
    assert_difference -> { Letter.count } => 1, -> { EmotionalSnapshot.count } => 1, -> { Prediction.count } => 5 do
      assert form.save
    end

    letter = form.letter
    assert_equal "My Future self", letter.title
    assert_equal "test@example.com", letter.email
    assert_equal "Hello from the past! I hope this message finds you in great spirits, thriving and healthy.", letter.content
    assert_equal "pending", letter.status
    assert_equal "America/Bogota", letter.timezone

    # 2027-05-20 00:00:00 -05:00 in Bogota is 2027-05-20 05:00:00 UTC
    assert_equal 5, letter.scheduled_at.utc.hour

    # Verify emotional snapshot
    snapshot = letter.emotional_snapshot
    assert_not_nil snapshot
    assert_equal 7, snapshot.happiness_level
    assert_equal 3, snapshot.anxiety_level
    assert_equal 8, snapshot.motivation_level

    # Verify predictions
    predictions = letter.predictions
    assert_equal 5, predictions.size
    assert_equal "Madrid", predictions.find_by(category: "city").prediction
    assert_equal "$90,000", predictions.find_by(category: "salary").prediction
  end

  test "invalid letter form validations" do
    valid_content = "This is a sufficiently long archival reflection intended for my future self after many years."

    # 1. Past deliver_at
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: valid_content,
      deliver_at: 1.day.ago
    )
    assert_not form.valid?
    assert form.errors[:deliver_at].any?

    # 2. Missing title
    form = LetterForm.new(
      email: "user@example.com",
      content: valid_content,
      deliver_at: 1.year.from_now
    )
    assert_not form.valid?
    assert form.errors[:title].any?

    # 3. Invalid email format
    form = LetterForm.new(
      title: "Title",
      email: "not-an-email",
      content: valid_content,
      deliver_at: 1.year.from_now
    )
    assert_not form.valid?
    assert form.errors[:email].any?

    # 4. Out of bounds emotional levels
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: valid_content,
      deliver_at: 1.year.from_now,
      happiness_level: 11
    )
    assert_not form.valid?
    assert form.errors[:happiness_level].any?

    # 5. Invalid timezone
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: valid_content,
      deliver_at: 1.year.from_now,
      timezone: "Mars/Olympus"
    )
    assert_not form.valid?
    assert form.errors[:timezone].any?

    # 6. Unparseable string date format
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: valid_content,
      deliver_at: "not-a-valid-date-string"
    )
    assert_not form.valid?
    assert_includes form.errors[:scheduled_at], I18n.t("errors.messages.invalid")

    # 7. Blank timezone returns early in valid_iana_timezone
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: valid_content,
      deliver_at: 1.year.from_now,
      timezone: ""
    )
    assert_not form.valid?
    assert form.errors[:timezone].any?

    # 8. Content fewer than 80 characters
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: "Short note",
      deliver_at: 1.year.from_now
    )
    assert_not form.valid?
    assert form.errors[:content].any?
  end

  test "parsed_utc_scheduled_at handles Date, Time, and non-parseable types" do
    # Date object
    form_date = LetterForm.new(deliver_at: Date.new(2028, 6, 15), timezone: "America/Bogota")
    assert_equal Time.find_zone("America/Bogota").local(2028, 6, 15).utc, form_date.parsed_utc_scheduled_at

    # Standard Time object
    time_now = Time.utc(2030, 1, 1, 10, 0, 0)
    form_time = LetterForm.new(deliver_at: time_now)
    assert_equal time_now, form_time.parsed_utc_scheduled_at

    # Fallback to UTC when timezone is unknown
    form_unknown_tz = LetterForm.new(deliver_at: "2030-01-01 12:00:00", timezone: "Unknown/Zone")
    assert_equal Time.find_zone("UTC").parse("2030-01-01 12:00:00").utc, form_unknown_tz.parsed_utc_scheduled_at

    # Unrecognized type returns nil
    form_int = LetterForm.new(deliver_at: 12345)
    assert_nil form_int.parsed_utc_scheduled_at
  end

  test "saving letter without predictions skips predictions and predictions_completed event" do
    form = LetterForm.new(
      title: "No predictions",
      email: "nopredictions@example.com",
      content: "Just a plain note to my future self to reflect upon after all these years of growth and work.",
      deliver_at: 1.year.from_now,
      prediction_city: "",
      prediction_salary: "",
      prediction_relationship: "",
      prediction_career: "",
      prediction_achievement: "",
      prediction_happiness: ""
    )

    assert form.valid?
    assert_difference -> { Letter.count } => 1, -> { Prediction.count } => 0 do
      assert form.save
    end
  end

  test "accepts empty predictions_attributes array and empty emotional_snapshot_attributes hash without unknown attribute error" do
    form = LetterForm.new(
      title: "Empty predictions array",
      email: "empty_preds@example.com",
      content: "Just a plain note to my future self to reflect upon after all these years of growth and work.",
      deliver_at: 1.year.from_now,
      emotional_snapshot_attributes: {},
      predictions_attributes: []
    )

    assert form.valid?
    assert_difference -> { Letter.count } => 1, -> { Prediction.count } => 0 do
      assert form.save
    end
  end

  test "produces Spanish validation error messages when locale is es" do
    I18n.with_locale(:es) do
      form = LetterForm.new(title: "", email: "invalid", content: "Corto", deliver_at: 1.day.ago)
      assert_not form.valid?
      sentence = form.errors.full_messages.to_sentence
      assert_includes sentence, "El título no puede estar en blanco"
      assert_includes sentence, "El contenido es demasiado corto"
      refute_match(/can't be blank|is too short|must be in the future/i, sentence)
    end
  end

  test "handles ActiveRecord::RecordInvalid on save" do
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: "This is a sufficiently long archival reflection intended for my future self after many years.",
      deliver_at: 1.year.from_now
    )

    fake_letter = Letter.new
    def fake_letter.save!
      raise ActiveRecord::RecordInvalid.new(Letter.new)
    end

    original_new = Letter.method(:new)
    Letter.define_singleton_method(:new, ->(attrs = {}) { fake_letter })

    assert_not form.save
    assert form.errors[:base].any?
  ensure
    Letter.define_singleton_method(:new, original_new.to_proc) if original_new
  end

  test "content structure validation rejects words longer than 45 characters" do
    long_word = "a" * 46
    form = LetterForm.new(
      title: "Title",
      email: "user@example.com",
      content: "Hello future self here is a word #{long_word} that is way too long to be valid in any sentence.",
      deliver_at: 1.year.from_now
    )

    assert_not form.valid?
    assert_includes form.errors[:content], I18n.t("errors.messages.word_too_long")
  end

  test "accepts long letters with a single paragraph" do
    long_single_paragraph = "This is a long reflection intended for my future self without any line breaks or paragraph structure whatsoever because a single paragraph is completely allowed. " * 3
    form = LetterForm.new(
      title: "Valid Title",
      email: "user@example.com",
      content: long_single_paragraph,
      deliver_at: 1.year.from_now
    )

    assert form.valid?, "Expected single paragraph long letter to be valid"
  end

  test "validates title length and word structure" do
    long_title = "T" * 101
    form = LetterForm.new(
      title: long_title,
      email: "user@example.com",
      content: "This is a sufficiently long reflection intended for my future self after many years of growth.",
      deliver_at: 1.year.from_now
    )

    assert_not form.valid?
    assert form.errors[:title].any?
  end

  test "enforces creation limit of 5 letters per 24 hours per email" do
    email = "frequent_writer@example.com"
    5.times do |i|
      letter = Letter.new(
        title: "Letter #{i + 1}",
        email: email,
        content: "Reflections from the past for number #{i + 1} that contains more than ten valid words.",
        scheduled_at: 1.year.from_now,
        status: "pending"
      )
      letter.save!(validate: false)
    end

    form = LetterForm.new(
      title: "Letter 6",
      email: email,
      content: "This is a sixth letter trying to exceed the daily creation limit for this user.",
      deliver_at: 1.year.from_now
    )

    assert_not form.valid?
    assert_includes form.errors[:base], I18n.t("errors.messages.letter_rate_limit_exceeded")

    # Another email is not limited
    other_form = LetterForm.new(
      title: "Another person",
      email: "another_writer@example.com",
      content: "This is an entirely different user who should not be restricted by the other email.",
      deliver_at: 1.year.from_now
    )
    assert other_form.valid?
  end
end
