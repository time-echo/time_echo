class PendingLettersQuery
  def self.call
    new.call
  end

  def call
    Letter.pending.lock("FOR UPDATE SKIP LOCKED")
  end
end
