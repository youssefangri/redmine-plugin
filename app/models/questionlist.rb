class Questionlist < ChecklistBase

  self.table_name = 'kanban_question_list'

  belongs_to :issue, :class_name => 'Issue', :foreign_key => 'issue_id', :optional => true
  has_many :questions

  def editable?(user = User.current)
    return true if user.admin?
    if issue.visible?(user) != true
      return false
    end

    if self.respond_to?('personal_editable?')
      return personal_editable?(user)
    end
    user.allowed_to?(:edit_checklists, issue.project)
  end

  def items
    Question.where(questionlist: self, deleted: false).order(sort_order: :asc, id: :asc)
  end

  def undone_items
    Question.where(questionlist: self, deleted: false, done: false).order(sort_order: :asc, id: :asc)
  end


end


