class QuestionController < ApplicationController

  PATCH_ACTION_DELETE = 'question.delete'.freeze
  PATCH_ACTION_COMPLETE = 'question.complete'.freeze
  PATCH_ACTION_SET_TITLE = 'question.set_title'.freeze
  PATCH_ACTION_SET_ANSWER = 'question.set_answer'.freeze
  PATCH_ACTION_DELETE_ANSWER = 'question.delete_answer'.freeze
  PATCH_ACTION_SET_ASSIGNED_TO = 'question.set_assigned_to'.freeze
  PATCH_ACTION_SET_DUE_DATE = 'question.set_due_date'.freeze
  PATCH_ACTION_SET_SORT_ORDER = 'question.set_order'.freeze
  unloadable

  include QuestionHelper
  include JournalHelper
  include ApiHelper
  include ControllerHelper

  before_action :find_questionlist_by_qid, :only => [:index, :create]
  before_action :find_item_by_id, :only => [:patch, :upload, :history, :update_attachment]
  before_action :check_item_updated_at, :only => [:patch]
  before_action :find_issue_by_id, :only => [:assignees]
  #after_action :update_issue, :only => [:create, :patch]

  helper

  def index
    data = []
    @questionlist.items.each do |r|
      data.push(transform_question(r))
    end

    render json: data
  rescue  StandardError => e
    api_exception e
  end

  def assignees
    data = []
    @issue.assignable_users.each do |r|
      data.push(transform_user(r))
    end

    render json: data
  rescue  StandardError => e
    api_exception e
  end

  def create
    record = Question.new
    record.title = params[:title]
    record.questionlist = @questionlist
    record.created_by = User.current
    record.sort_order = Question.where(questionlist: @questionlist).length
    record.set_assigned_to(params[:assigned_to_id]) if params[:assigned_to_id]
    record.set_due_date(params[:due_date]) if params[:due_date]
    unless record.save
      api_validation_errors(record)
      return false
    end
    render json: transform_question(record)
  rescue  StandardError => e
    api_exception e
  end

  def patch
    case params[:data][:action]
    when PATCH_ACTION_DELETE
      @question.set_deleted true
    when PATCH_ACTION_COMPLETE
      @question.set_completed params[:data][:value]
    when PATCH_ACTION_SET_TITLE
      @question.set_title params[:data][:value]
    when PATCH_ACTION_SET_ANSWER
      @question.set_answer params[:data][:value]
    when PATCH_ACTION_DELETE_ANSWER
      @question.delete_answer
    when PATCH_ACTION_SET_ASSIGNED_TO
      @question.set_assigned_to params[:data][:value]
    when PATCH_ACTION_SET_DUE_DATE
      @question.set_due_date params[:data][:value]
    when PATCH_ACTION_SET_SORT_ORDER
      @question.set_order params[:data][:value].to_i
    else
      api_one_error(l(:invalid_action_attribute))
      return
    end

    unless @question.save
      api_validation_errors(@question)
      return
    end

    api_updated_at @question.updated_at
  rescue ActiveRecord::RecordNotFound
    api_404
    return
  rescue  StandardError => e
    api_exception e
  end







  private









end
