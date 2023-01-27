class QuestionlistController < ApplicationController
  PATCH_ACTION_DELETE = 'questionlist.delete'.freeze
  PATCH_ACTION_SET_TITLE = 'questionlist.set_title'.freeze

  unloadable

  # include QuestionlistHelper
  include KanbanHelper
  include ApiHelper
  include QuestionHelper

  before_action :find_issue_by_id, :only => [:index, :create]
  before_action :find_questionlist_by_id, :only =>[:patch, :assign]
  before_action :check_checklist_updated_at, :only => [:patch, :assign]
  #after_action :update_issue, :only => [:create, :patch]

  helper

  def index

    data = []
    @issue.questionlists.each do |r|
      data.push(transform_questionlist(r))
    end

    render json: data
  rescue  StandardError => e
    api_exception e
  end

  def create
    if params[:list_type] === ChecklistBase::TYPE_USUAL
      type = ChecklistBase::TYPE_USUAL
      @issue.can_add_checklist?(User.current)|| (raise Unauthorized)
    else
      type = ChecklistBase::TYPE_PERSONAL
      @issue.can_add_personal_checklist?(User.current)|| (raise Unauthorized)
    end

    record = Questionlist.new
    record.title = params[:title]
    record.issue = @issue
    record.created_by = User.current
    record.list_type = type

    unless record.save
      render_validation_errors(record)
      return false
    end

    render json: transform_questionlist(record)
  end

  def patch
    @questionlist.editable? || (raise Unauthorized)
    case params[:data][:action]
    when PATCH_ACTION_DELETE
      @questionlist.set_deleted true
    when PATCH_ACTION_SET_TITLE
      @questionlist.set_title params[:data][:value]
    else
      api_one_error(l(:invalid_action_attribute))
      return
    end

    unless @questionlist.save
      api_validation_errors(@questionlist)
      return false
    end

    render json: { updatedAt: @questionlist.updated_at }
  end

  def assign
    @questionlist.undone_items.each do |r|
      if r.editable?
        r.set_assigned_to params[:data][:value]
        r.save || render_validation_errors(r)
      end
    end

    @questionlist.reload
    render json: transform_questionlist(@questionlist)

  rescue ActiveRecord::RecordNotFound => e
    api_404 e.message
  rescue  StandardError => e
    api_exception e
  end

  private

  include ControllerHelper






end
