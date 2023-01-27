module ControllerHelper

  def build_query
    if params[:query_id]
      @query = KanbanQuery.find(params[:query_id])
    elsif
    @query = KanbanQuery.new(:name => "_")
      @query.user = User.current
      @query.project = @project
      @query.build_from_params(params)
    end
  end

  def check_issue_updated_at
    if DateTime.parse(params[:updated_on]).to_i != @issue.updated_on.to_i
      api_errors l(:notice_issue_update_conflict)
    end
  end

  def check_item_updated_at
    if params[:data][:updated_at].nil?
      api_one_error "updated_at required"
      return
    end
    if (DateTime.parse(params[:data][:updated_at]).to_i-@question.updated_at.to_i).abs >0
      api_one_error(l(:notice_issue_update_conflict))
      return
    end
  rescue TypeError => e
    api_one_error "updated_at wrong format"
    return
  rescue StandardError => e
    api_exception e
    return
  end

  def check_checklist_updated_at
    if params[:data][:updated_at].nil?
      api_one_error "updated_at required"
      return
    end

    if DateTime.parse(params[:data][:updated_at]).to_i != @questionlist.updated_at.to_i
      api_one_error(l(:notice_issue_update_conflict))
      return
    end
  rescue TypeError => e
    api_one_error "updated_at required"
    return
  rescue StandardError => e
    api_exception e
    return
  end

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  end

  def find_questionlist_by_qid
    @questionlist = Questionlist.find(params[:questionlist_id])
    @issue = @questionlist.issue
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  rescue  StandardError => e
    api_exception e
    return
  end

  def find_item_by_id
    @question = Question.find(params[:id])
    @issue = @question.questionlist.issue
    api_403 unless @issue.visible?
    @project = @issue.project

    if @question.questionlist.is_type_personal?
      @question.editable?(User.current) || (raise Unauthorized)
    end
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  end

  def find_questionlist_by_id
    @questionlist = Questionlist.find(params[:id])
    @issue = @questionlist.issue
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  end
end