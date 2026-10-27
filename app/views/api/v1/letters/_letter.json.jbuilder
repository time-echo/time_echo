# frozen_string_literal: true

json.id letter.id.to_s
json.docket_number "TE-#{letter.id.to_s.rjust(5, '0')}"
json.title letter.title
json.content letter.content
json.email letter.email
json.scheduled_at letter.scheduled_at&.iso8601
json.delivered_at letter.delivered_at&.iso8601
json.opened_at letter.opened_at&.iso8601
json.queued_at letter.queued_at&.iso8601
json.status letter.status
json.language letter.language
json.timezone letter.timezone
json.reveal_happiness letter.reveal_happiness
json.reveal_anxiety letter.reveal_anxiety
json.reveal_motivation letter.reveal_motivation
json.is_wax_broken letter.opened_at.present?
json.created_at letter.created_at&.iso8601
json.updated_at letter.updated_at&.iso8601

if letter.emotional_snapshot.present?
  json.emotional_snapshot do
    json.id letter.emotional_snapshot.id.to_s
    json.letter_id letter.id.to_s
    json.happiness_level letter.emotional_snapshot.happiness_level
    json.anxiety_level letter.emotional_snapshot.anxiety_level
    json.motivation_level letter.emotional_snapshot.motivation_level
    json.created_at letter.emotional_snapshot.created_at&.iso8601
    json.updated_at letter.emotional_snapshot.updated_at&.iso8601
  end
else
  json.emotional_snapshot nil
end

json.predictions letter.predictions do |pred|
  json.id pred.id.to_s
  json.letter_id letter.id.to_s
  json.category pred.category
  json.prediction pred.prediction
  json.reality pred.reality
  json.matched pred.matched
  outcome = pred.matched.nil? ? "pending" : (pred.matched ? "fulfilled" : "diverged")
  json.outcome outcome
  json.created_at pred.created_at&.iso8601
  json.updated_at pred.updated_at&.iso8601
end
