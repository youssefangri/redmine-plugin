module JournalHelper

  def self.create_journal(issue, user, time, note = nil)
    journal = Journal.new
    journal.journalized = issue
    journal.user = user
    journal.created_on = time
    if note != nil
      journal.notes = note
    end
    journal.save!

    journal
  end

  def self.create_journal_details(prop, key, o, n, journal)
    journalDetails = JournalDetail.new(
      :property => prop,
      :prop_key => key,
      :old_value => o,
      :value => n
    )
    journalDetails.journal = journal
    journalDetails.save!
    journalDetails
  end

  private

end
