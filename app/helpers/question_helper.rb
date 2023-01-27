module QuestionHelper
  include CommonHelper

  def transform_question(record)
    i = {
      editable: record.editable?,
      id: record.id,
      title: record.title,
      done: record.done,
      answer: record.answer,
      answered_at: record.answered_at,
      assigned_to: record.assigned_to.nil? ? nil : record.assigned_to.name,
      answered_by: record.answered_by.nil? ? nil : record.answered_by.name,
      assigned_to_id: record.assigned_to.nil? ? nil : record.assigned_to.id,
      completed_at: record.completed_at,
      completed_by: record.completed_by.nil? ? nil : record.completed_by.name,
      due_date: record.get_due_date,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by: user_name_or_anonymous(record.created_by),
    }
    i[:attachments] = record.attachments.map { |a| transform_attachment a } if record.respond_to?('attachments')
    i
  end

  def transform_attachment( attachment)
    {
      id: attachment.id,
      filename: attachment.filename,
      filesize: attachment.filesize,
      author: user_name_or_anonymous(attachment.author),
      created_on: attachment.created_on,
      description: attachment.description,
    }
  end

  def transform_questionlist(record)
    {
      editable: record.editable?,
      id: record.id,
      title: record.title,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by: user_name_or_anonymous(record.created_by),
      deleted: record.deleted,
      list_type: record.list_type,
      tasks: record.items.map { |question| transform_question(question) }
    }
  end

  def transform_questionlist_info(record)
    res = {}
    res['id'] = record.id
    res['title'] = record.title

    questions_total = 0
    questions_completed = 0
    assignees = []
    record.items.each do |r|
      questions_total += 1
      if r.done
        questions_completed += 1
      end
      unless r.done == true || r.assigned_to == nil || assignees.detect {|f| f['id'] == r.assigned_to.id }
        assignees << transform_user(r.assigned_to)
      end
    end

    res['questions_total'] = questions_total
    res['questions_completed'] = questions_completed
    res['assignees'] = assignees
    res['deleted'] = record.deleted
    res['list_type'] = record.list_type

    res
  end


end
