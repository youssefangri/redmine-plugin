class ChecklistItemBase < ActiveRecord::Base
  self.abstract_class = true
  include Redmine::SafeAttributes
  include JournalHelper
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :assigned_to, :class_name => "Principal", :foreign_key => "assigned_to_id"

  validates_presence_of :title
  validates_length_of :title, maximum: 1000

  validates_presence_of :sort_order
  validates_numericality_of :sort_order

  validates_presence_of :assigned_to, if: :is_assigned_to_required?

  def set_order(data)
    count = 0
    self.questionlist.items.each do |i|
      count+=1 if count == data
      if i.id == self.id
          self.sort_order = data
          count < data ? count += -1 : count += 1
      else
        i.sort_order = count
      end

      i.save(touch: false)
      count += 1
    end
  end

  def set_title(data)
    self.title = data
  end

  def set_deleted(data)
    self.deleted = data
  end

end