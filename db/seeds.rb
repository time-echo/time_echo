# Reset tables to avoid duplication
Prediction.delete_all
EmotionalSnapshot.delete_all
AnalyticsEvent.delete_all
Letter.delete_all
Stamp.delete_all
StampCategory.delete_all

puts "Seeding TimeEcho digital vaults..."

load Rails.root.join("db/seeds/stamps.rb")

# 1. Pre-delivered letter with completed predictions and emotional evolution
delivered_letter = Letter.new(
  title: "A promise to my future self",
  content: "Dear future self,\n\nToday I am sitting in my room, listening to low-fi music, wondering where life will take me. I am feeling a bit anxious about my job situation and whether I will ever move to a different city. My relationship status is single, and I spend most of my time coding or learning new frameworks. I hope that when you open this, you have found a stable tech role, feel calmer, and have completed that marathon we planned.\n\nKeep growing, and never forget where you started.\n\nWarmly,\nYour Past Self",
  email: "user@example.com",
  status: "delivered",
  deliver_at: 1.year.ago,
  delivered_at: 1.year.ago,
  reveal_happiness: 8,
  reveal_anxiety: 3,
  reveal_motivation: 9,
  stamp: Stamp.find_by(slug: "morning-coffee")
)
delivered_letter.save!(validate: false)

# Build emotional snapshot at creation (1 year ago)
delivered_letter.create_emotional_snapshot!(
  happiness_level: 4,
  anxiety_level: 7,
  motivation_level: 5
)

# Build predictions made at creation
delivered_letter.predictions.create!([
  { category: "city", prediction: "I will still live in Bogotá", reality: "Now living in Medellín", matched: false },
  { category: "salary", prediction: "$60,000/year", reality: "$85,000/year", matched: true },
  { category: "relationship", prediction: "enjoying single life", reality: "in a beautiful, supportive relationship", matched: false },
  { category: "career", prediction: "Junior Web Developer", reality: "Senior Rails Engineer at a premium startup", matched: true },
  { category: "achievement", prediction: "completed a full marathon", reality: "ran a half-marathon and completed a 100-day meditation streak", matched: false }
])

# Create historical analytics events for delivered letter
AnalyticsEvent.create!([
  { event_type: "letter_created", metadata: { email: "user@example.com" }, occurred_at: 1.year.ago },
  { event_type: "emotional_snapshot_completed", metadata: { email: "user@example.com" }, occurred_at: 1.year.ago },
  { event_type: "predictions_completed", metadata: { email: "user@example.com" }, occurred_at: 1.year.ago },
  { event_type: "email_delivered", metadata: { letter_id: delivered_letter.id, email: "user@example.com" }, occurred_at: 1.year.ago },
  { event_type: "letter_opened", metadata: { letter_id: delivered_letter.id, email: "user@example.com" }, occurred_at: 11.months.ago },
  { event_type: "prediction_completion", metadata: { letter_id: delivered_letter.id, email: "user@example.com" }, occurred_at: 11.months.ago },
  { event_type: "emotional_snapshot_completion", metadata: { letter_id: delivered_letter.id, email: "user@example.com" }, occurred_at: 11.months.ago }
])


# 2. Pre-delivered letter that has NOT been completed yet (NEEDS REFLECTION / REALITY UPDATE)
pending_reflection_letter = Letter.new(
  title: "Hopes for my 25th Birthday",
  content: "Hey self,\n\nYou are turning 25 today. I hope you got that driver's license, learned how to bake sourdough bread, and are finally sleeping 8 hours a night. Today we are highly motivated but also highly anxious. Let's see if we did it!",
  email: "user@example.com",
  status: "delivered",
  deliver_at: 1.day.ago,
  delivered_at: 1.day.ago,
  stamp: Stamp.find_by(slug: "one-more-year")
)
pending_reflection_letter.save!(validate: false)

pending_reflection_letter.create_emotional_snapshot!(
  happiness_level: 6,
  anxiety_level: 8,
  motivation_level: 9
)

pending_reflection_letter.predictions.create!([
  { category: "city", prediction: "living in Berlin" },
  { category: "career", prediction: "Freelance Designer" },
  { category: "achievement", prediction: "baking beautiful sourdough bread" }
])

# Create historical analytics events
AnalyticsEvent.create!([
  { event_type: "letter_created", metadata: { email: "user@example.com" }, occurred_at: 6.months.ago },
  { event_type: "emotional_snapshot_completed", metadata: { email: "user@example.com" }, occurred_at: 6.months.ago },
  { event_type: "predictions_completed", metadata: { email: "user@example.com" }, occurred_at: 6.months.ago },
  { event_type: "email_delivered", metadata: { letter_id: pending_reflection_letter.id, email: "user@example.com" }, occurred_at: 1.day.ago },
  { event_type: "letter_opened", metadata: { letter_id: pending_reflection_letter.id, email: "user@example.com" }, occurred_at: 1.day.ago }
])


# 3. Sealed pending letter (awaiting future delivery) - created without a stamp (fallback test)
sealed_letter = Letter.new(
  title: "Letter to 5 years in the future",
  content: "Hello future me,\n\nWriting this from the year 2026. I hope you have traveled to Japan, found deep peace of mind, and are still coding Rails with joy. Remember to call mom once a week and drink water.\n\nPeace,\nMe",
  email: "user@example.com",
  status: "pending",
  deliver_at: 5.years.from_now
)
sealed_letter.save! # This one is in the future, so normal save passes!

# Build emotional snapshot
sealed_letter.create_emotional_snapshot!(
  happiness_level: 7,
  anxiety_level: 4,
  motivation_level: 8
)

# Build predictions
sealed_letter.predictions.create!([
  { category: "city", prediction: "living in Vancouver or Tokyo" },
  { category: "salary", prediction: "$140,000/year" },
  { category: "career", prediction: "Principal Architect or Startup Founder" }
])

# Create historical analytics events
AnalyticsEvent.create!([
  { event_type: "letter_created", metadata: { email: "user@example.com" }, occurred_at: Time.current },
  { event_type: "emotional_snapshot_completed", metadata: { email: "user@example.com" }, occurred_at: Time.current },
  { event_type: "predictions_completed", metadata: { email: "user@example.com" }, occurred_at: Time.current }
])

puts "TimeEcho database seeded successfully!"
