class KanbanController < ApplicationController
  menu_item :kanban
  require 'json'

  include ProjectsHelper
  include QueriesHelper
  include KanbanHelper
  include ApiHelper
  helper TranslationHelper
  include StatusesHelper

  before_action :find_optional_project, :build_query, only: [
    :index, :get_issues, :set_sort_order, :set_issue_status
  ]

  before_action :find_issue, only: [
    :set_issue_status, :get_issue, :patch
  ]

  before_action :check_issue_updated_at, only: [
    :set_issue_status, :patch
  ]

  def index
    @settings = get_board_settings
  end

  def get_issues
    items = @query.issues(limit: 500)
    data = format_issues items

    render json: data
  end

  def get_issue
    api_answer format_issue(Issue.find(params[:id]))
  end

  def set_issue_status
    status_id = params[:status_id].to_i

    if User.current.allowed_to?(:edit_issues, @project) && @issue.new_statuses_allowed_to.select { |item| item.id == status_id }.any?
      @issue.init_journal(User.current)
      @issue.status_id = status_id
      if @issue.save
        # head :ok
        render json: format_issues(@query.issues(limit: 500))
      else
        render json: {"errors" => @issue.errors.full_messages }, status: 403
      end
    else
      render json: {"errors" =>  l(:kanban_rejected_status) }, status: 403
    end
  rescue  StandardError => e
    api_exception e
  end

  private


  def get_board_settings
    {
      'query' => request.GET.empty? ? to_arr(@query) : request.GET ,
      'id' => @project ? @project.identifier : nil,
      'statuses' => format_statuses(@query.get_statuses, []),
      'swimlanes' => @query.group_by_column ? get_swimlanes(@query) : {:name => nil},
      'show_card_properties' => @query.columns.map do |column|
        # @TODO in free version should be column.name
        column.respond_to?(:custom_field) ? column.custom_field.name : column.name
      end
    }
  end

  include ControllerHelper

end
