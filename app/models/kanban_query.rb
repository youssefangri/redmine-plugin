# Class for issue queries on kanban board
# frozen_string_literal: false
class KanbanQuery < IssueQuery
  self.queried_class = Issue
  self.view_permission = :view_issues


  class_attribute :all_statuses
  # self.available_statuses = []

  self.available_columns = [
    QueryColumn.new(:id, sortable: "#{Issue.table_name}.id", default_order: 'desc', caption: '#', frozen: false , inline: false ),
    QueryColumn.new(:project, groupable: "#{Issue.table_name}.project_id", sortable: "#{Project.table_name}.id", inline: false),
    QueryColumn.new(:tracker, sortable: "#{Tracker.table_name}.position", groupable: true, inline: false ),
    QueryColumn.new(
      :parent,
      sortable: ["#{Issue.table_name}.root_id", "#{Issue.table_name}.lft ASC"],
      default_order: 'desc',
      caption: :field_parent_issue,
      inline: false
    ),
    # QueryAssociationColumn.new(:parent, :subject, caption: :field_parent_issue_subject, inline: false),
    QueryColumn.new(:status, sortable: "#{IssueStatus.table_name}.position", groupable: false),
    QueryColumn.new(:priority, groupable: "#{Issue.table_name}.priority_id", inline: false),
    QueryColumn.new(:subject, sortable: "#{Issue.table_name}.subject" , inline: false),
    QueryColumn.new(:author, sortable: -> { User.fields_for_order_statement('authors') }, groupable: true, inline: false),
    QueryColumn.new(
      :assigned_to,
      sortable: -> { User.fields_for_order_statement },
      groupable: "#{Issue.table_name}.assigned_to_id",
      inline: false
    ),
    QueryColumn.new(
      :updated_on,
      sortable: "#{Issue.table_name}.updated_on",
      default_order: 'desc',
      groupable: false,
      inline: false
    ),
    # QueryColumn.new(:category, sortable: "#{IssueCategory.table_name}.name", groupable: true),
    # QueryColumn.new(:fixed_version, sortable: -> { Version.fields_for_order_statement }, groupable: true),
    # QueryColumn.new(:start_date, sortable: "#{Issue.table_name}.start_date", groupable: true),
    QueryColumn.new(:due_date, sortable: "#{Issue.table_name}.due_date", groupable: false, inline: false),
    # QueryColumn.new(:estimated_hours, sortable: "#{Issue.table_name}.estimated_hours", totalable: true),
    QueryColumn.new(
      :total_estimated_hours,
      sortable: lambda {
        "COALESCE((SELECT SUM(estimated_hours) FROM #{Issue.table_name} subtasks" \
        " WHERE #{Issue.visible_condition(User.current).gsub(/\bissues\b/, 'subtasks')}" \
        " AND subtasks.root_id = #{Issue.table_name}.root_id" \
        " AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)"
      },
      default_order: 'desc',
      inline: false
    ),
    # QueryColumn.new(:done_ratio, sortable: "#{Issue.table_name}.done_ratio", groupable: true),
    QueryColumn.new(
      :created_on,
      sortable: "#{Issue.table_name}.created_on",
      default_order: 'desc',
      groupable: false
    ),
    # TimestampQueryColumn.new(
    #   :closed_on,
    #   sortable: "#{Issue.table_name}.closed_on",
    #   default_order: 'desc',
    #   groupable: true,
      
    # ),
    # QueryColumn.new(:last_updated_by, sortable: -> { User.fields_for_order_statement('last_journal_user') }, inline: true),
    # QueryColumn.new(:relations, caption: :label_related_issues),
    # QueryColumn.new(:attachments, caption: :label_attachment_plural, inline: false),
    # QueryColumn.new(:description, inline: false),
    # QueryColumn.new(:last_notes, caption: :label_last_notes, inline: false),
    QueryColumn.new(:questionlist, caption: :label_checklist_plural, inline: false),
  ]

  def self.default_filters
    # values = [User.current.id.to_s]
    # User.current.group_ids.each { |group_id| values.push(group_id.to_s) }

    {
      'status_id' => { operator: 'a', values: [] },
      # 'assigned_to_id' => { operator: '=', values: ['me'] }
    }
  end

  def initialize(attributes=nil, *args)
    super attributes
    options[:statuses]=[]
    self.filters = self.filters == {'status_id' => {:operator => "a", :values => []}} ? KanbanQuery.default_filters : self.filters
  end

  def build_from_params(params, defaults={})
    super
    if params[:s].nil? || params[:s].empty?
      res =  available_statuses.select {|c| c.is_closed == false }
    else
      res =  available_statuses.select{|s| params[:s].include? s.id.to_s  }
    end
    options[:statuses] = res.collect {|s| s.id }
    if self.group_by_column && self.group_by_column.name
      a = column_names
      a << self.group_by_column.name
      self.column_names = a
    end
    write_attribute(:options, options)
    self
  end

  def available_columns
     return @available_columns if @available_columns
     super
    if KanbanQuery.redmineup_tags_installed
      @available_columns << QueryColumn.new(:tags, caption: :tags, inline: false)
    end
    @available_columns
  end

  def self.redmineup_tags_installed
    defined?(RedmineupTags) == 'constant' && RedmineupTags.class == Module
  end

  def default_columns_names
    @default_columns_names ||= begin
      default_columns = [:subject, :assigned_to, :tracker, :id, :total_spent_hours, :total_estimated_hours, :updated_on, :due_date, :assigned_to, :author, :questionlist, :project, :priority, :tags]
      project.present? ? default_columns : [:project] | default_columns
    end
  end


  def available_board_columns
    available_columns.reject{|c| [:status, :spent_hours, :estimated_hours].include? c.name}
  end

  def default_sort_criteria
    [['priority', 'desc']]
  end

  def base_scope
    Issue.visible.joins(:status, :project).left_joins(:kanban_issue).where(statement)
  end



  def issues(options={})
    # order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
    # The default order of IssueQuery is issues.id DESC(by IssueQuery#default_sort_criteria)
    # unless ["#{Issue.table_name}.id ASC", "#{Issue.table_name}.id DESC"].any?{|i| order_option.include?(i)}
    #   order_option << "#{Issue.table_name}.id DESC"
    # end


    order_option = ["#{KanbanIssue.table_name}.sort_order ASC", "#{Enumeration.table_name}.position DESC", "#{Issue.table_name}.id ASC"]
    # order_option = "#{KanbanIssue.table_name}.sort_order ASC"



    if  (statuses.nil? || statuses.empty? )
      "1 = 1"
    else
      statement_show_statuses = "issues.status_id IN ("+ statuses.join(', ')+ ")"
    end
    

    scope = Issue.visible
      .joins(:status, :project)
      .left_joins(:kanban_issue)
      .preload(:priority)
      .where(kanban_projects)
      .where(statement)
      .where(statement_show_statuses)
      .includes(([:status, :project, :kanban_issue] + (options[:include] || [])).uniq)
      .where(options[:conditions])
      .order(order_option)
      .joins(joins_for_order_statement(order_option.join(',')))
      .limit(options[:limit])
      .offset(options[:offset])

    scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))
    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end

    issues = scope.to_a

    has_column?(:spent_hours) && Issue.load_visible_spent_hours(issues)
    has_column?(:total_spent_hours) && Issue.load_visible_total_spent_hours(issues)
    has_column?(:last_updated_by) && Issue.load_visible_last_updated_by(issues)
    has_column?(:relations) && Issue.load_visible_relations(issues)
    has_column?(:last_notes) && Issue.load_visible_last_notes(issues)

    issues
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def kanban_projects
    # TODO need refactor: too many queries to db
    if project
      ids = [project.id]
      ids += project.descendants.select { |sub| sub.module_enabled?('kanban') }.map(&:id) if Setting.display_subprojects_issues?
    else
      ids = []
      ids += Project.all.select { |sub| sub.module_enabled?('kanban') }.map(&:id)
    end
    ids.any? ? "#{Project.table_name}.id IN (#{ids.join(',')})" : '1=0'
  end

  def sql_for_assigned_to_id_field(field, operator, value)
    sql = sql_for_field(field, operator, value, Issue.table_name, :assigned_to_id)
    case operator
    when '='
      checklist_items_sql = "#{Issue.table_name}.id IN" \
      " (SELECT DISTINCT(issue_id) FROM #{Questionlist.table_name}" \
      " LEFT JOIN #{Question.table_name} ON #{Question.table_name}.questionlist_id = #{Questionlist.table_name}.id" \
      " WHERE #{Questionlist.table_name}.deleted = 0 AND #{sql_for_field(field, operator, value, Question.table_name, :assigned_to_id)} AND #{Question.table_name}.done = 0 AND #{Question.table_name}.deleted = 0))"
      sql = sql.insert(0, '(') << " OR #{checklist_items_sql}"
    end

    sql
  end

# Kanban methods
  def statuses
    options[:statuses] || []
  end

# return entities
  def get_statuses
    available_statuses.select{|s| statuses.include? s.id  }
  end


  def set_statuses=(ids)
    open_statuses = available_statuses.select{ |s| s.is_closed == false }.  map{|s| s.id.to_i}
    # save blank if all statuses selected
    if ids.count == open_statuses.count && (ids-open_statuses).empty?
      options[:statuses] = []
    else
      options[:statuses] = ids
    end
    write_attribute(:options, options)
  end

  def available_statuses
    @all_statuses ||= begin
                       @all_statuses = project ? project.rolled_up_statuses.to_a : IssueStatus.all.sorted.to_a
                     end
    @all_statuses
  end

  def has_status?(status)
    if statuses.find {|c| c.to_i == status}
      return true
    else
      return false
    end
  end

  def groupable_columns
    method = Redmine::VERSION.to_s > '4.2' ? :groupable? : :groupable
    available_columns.select { |c| c.public_send(method) && !c.is_a?(QueryCustomFieldColumn) }
  end

end
