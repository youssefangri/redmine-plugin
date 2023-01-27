class KanbanIssue < ActiveRecord::Base
  unloadable
  belongs_to :issue
  validates :block_reason, length: { maximum: 1000, too_long: '%{count} characters is the maximum allowed' }, allow_blank: true

  before_save :update_fields


  private



  def update_fields
    # return unless self.block_reason_changed? || self.blocked_at_changed?
    if self.block_reason_changed? || self.blocked_at_changed?
      self.block_reason.strip!
      if !self.block_reason.blank? || !self.block_reason_was.blank?
        if issue.current_journal.nil?
          journal = JournalHelper.create_journal self.issue, User.current, Time.now
        else
          journal = issue.current_journal
        end
        journal.save! # need use with !
        JournalHelper.create_journal_details 'attr', 'block_reason', self.block_reason_was, self.block_reason, journal
        if self.blocked_at_changed? && !self.block_reason.blank?
          JournalHelper.create_journal_details 'attr', 'blocked_at', self.blocked_at_was, self.blocked_at, journal
        end
      end

      if self.block_reason_was.present?
        self.block_reason.present? || self.blocked_at = nil
      else
        self.blocked_at.present? || self.blocked_at = Time.now
      end
    end
  end
end
