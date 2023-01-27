module KanbanHelper
  include QueriesHelper
  include CommonHelper
  include IssuesHelper
  include QuestionHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::DateHelper

  def format_issue_base(issue)
    item ={}
    item[:id] = issue.id
    item[:status_id] = issue.status.id
    item[:status_name] = issue.status.name
    item[:subject] = issue.subject
    item[:block_reason] = issue.kanban_issue ? issue.kanban_issue.block_reason : nil
    item[:blocked_at] = issue.kanban_issue ? issue.kanban_issue.blocked_at : nil
    item[:updated_on] = issue.updated_on
    item
  end


  def format_issues(items)
    result = []
    items.each do |issue|
      item = format_issue_base(issue)

      if @query.has_column?(:tracker)
        item[:tracker] = issue.tracker.name
        item[:tracker_id] = issue.tracker.id
      end


      if @query.has_column?(:project)
        item[:project_id] = issue.project.id
        item[:project_name] = issue.project.name
      end

      @query.has_column?(:created_on) && item[:created_on] = issue.created_on
      @query.has_column?(:author) && item[:author] = user_name_or_anonymous(issue.author)
      # @query.has_column?(:assigned_to) &&

      if @query.has_column?(:priority)
        item[:priority_id] = issue.priority_id
        item[:priority_name] = issue.priority.name
      end

      if !issue.disabled_core_fields.include?('due_date') && @query.has_column?(:due_date)
        item[:due_date] = issue.due_date
        item[:due_date_human] = issue_due_date_details issue
      end

      if !issue.disabled_core_fields.include?('estimated_hours') && @query.has_column?(:total_estimated_hours)
        item[:total_estimated_hours] = issue.total_estimated_hours
      end
      if User.current.allowed_to?(:view_time_entries, issue.project) && issue.total_spent_hours > 0 && @query.has_column?(:total_spent_hours)
        item[:total_spent_hours] = issue.total_spent_hours
      end

      if @query.has_column?(:parent) && !issue.parent_issue_id.nil?
        item[:parent_id] = issue.parent_issue_id
        item[:parent_name] = Issue.find_by(:id=> issue.parent_issue_id).nil? ? "" : Issue.find_by(:id=> issue.parent_issue_id).subject
      end
      @query.has_column?(:updated_on) && item[:updated_on] = issue.updated_on

      @query.has_column?(:subject) && item[:subject] = issue.subject
      @query.has_column?(:is_private) && item[:is_private] = issue.is_private?

      if !issue.disabled_core_fields.include?('assigned_to_id') && @query.has_column?(:assigned_to) && !issue.assigned_to_id.nil?
        user = user_or_anonymous(issue.assigned_to)
        item[:assigned_to_id] = issue.assigned_to_id
        item[:assigned_to] = user.name
        item[:assigned_to_type] = user.type
      end

      if issue.blocked?
        blocks = []
        issue.relations.select {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed? && ir.issue_to.id == issue.id }.map do |relation|
          i ={}
          i[:id] = relation.other_issue(issue).id
          i[:subject] = relation.other_issue(issue).subject
          blocks << i
        end
        item[:blocked_by_issues] = blocks
      end

      if @query.has_column?(:questionlist) && issue.project.module_enabled?('checklists')
        item[:question_lists] = issue.questionlists.map { |checklist| transform_questionlist_info(checklist) }
      end

      if KanbanQuery.redmineup_tags_installed && @query.has_column?(:tags)
        item[:tags] = format_issue_tags(issue)
      end

      item[:order] = issue.kanban_issue.sort_order
      
      result << item
    end
   
    result
  end

  def format_issue_core_fields(issue)
    r = {}
    unless issue.disabled_core_fields.include?('assigned_to_id')
      r[:assigned_to] = issue.assigned_to.nil? ? {} : { id: issue.assigned_to.id, name: issue.assigned_to.name }
    end
    unless issue.disabled_core_fields.include?('category_id') || (issue.category.nil? && issue.project.issue_categories.none?)
      r[:category_id] = issue.category ? issue.category.id : nil
      r[:category_name] = issue.category ? issue.category.name : "-"
    end

    # unless @issue.disabled_core_fields.include?('fixed_version_id') || (@issue.fixed_version.nil? && @issue.assignable_versions.none?)
    #   rows.left l(:field_fixed_version), (@issue.fixed_version ? link_to_version(@issue.fixed_version) : "-"), :class => 'fixed-version'
    # end

    unless issue.disabled_core_fields.include?('start_date')
      r[:start_date_details] = format_date issue.start_date
    end
    unless issue.disabled_core_fields.include?('done_ratio')
      r[:done_ratio] = issue.done_ratio
    end

    unless issue.disabled_core_fields.include?('due_date')
      r[:due_date] = issue.due_date
      r[:due_date_human] = issue_due_date_details issue
    end
    unless issue.disabled_core_fields.include?('estimated_hours')
      r[:estimated_hours] = issue_estimated_hours_details(issue)
    end
    if User.current.allowed_to?(:view_time_entries, issue.project) && issue.total_spent_hours > 0
      r[:spent_hours] = issue_spent_hours_details(issue)
    end
    r
  end

  def format_children(issue)
    all = []
    issue.children.map do |child|
      all << {
        id: child.id,
        subject: child.subject,
        status: child.status.name,
        due_date: child.due_date,
        assigned_to: child.assigned_to.nil? ? l(:label_user_anonymous) : child.assigned_to.name ,
        is_closed: child.closed?,
      }

    end
    all
  end

  def format_issue(issue)
    # changesets = issue.changesets.visible.preload(:repository, :user).to_a
    api = {
      author: { id: issue.author.id, name: user_name_or_anonymous(issue.author) },
      closed_on: issue.closed_on,
      created_on: issue.created_on,
      description: issue.description,
      fixed_version_id: issue.fixed_version_id,
      is_private: issue.is_private?,
      lock_version: issue.lock_version,
      priority_id: issue.priority_id,
      priority: issue.priority.name,
      project_id: issue.project_id,
      project_name: issue.project.name,
      subject: issue.subject,
      tracker_id: issue.tracker_id,
      tracker: issue.tracker.name,
      question_lists_can_add: issue.editable?,
      question_lists_can_add_visa: issue.editable?,
      question_lists: issue.questionlists.map { |checklist| transform_questionlist(checklist) },
      relations: issue.relations.map do |relation|
          {
            type: l(IssueRelation::TYPES[relation.relation_type][ (relation.issue_from_id == issue.id) ? :name : :sym_name]),
            other_id: (relation.issue_from_id == issue.id) ? relation.issue_to_id : relation.issue_from_id,
            subject: relation.other_issue(issue).subject,
            status: relation.other_issue(issue).status.name,
            due_date: relation.other_issue(issue).due_date,
            assigned_to: relation.other_issue(issue).assigned_to.nil? ? l(:label_user_anonymous) : relation.other_issue(issue).assigned_to.name ,
            is_closed: relation.other_issue(issue).closed?,
          }

      end
    }


    api = api.merge(format_issue_base(issue))
    api = api.merge(format_issue_core_fields(issue))
    api[:children] = format_children(issue) if issue.children?

    api[:attachments] = []
    issue.attachments.map do |attachement|
      api[:attachments] << transform_attachment(attachement)
    end

    if !issue.parent_issue_id.nil?
      api = api.merge(format_issue_parent(issue))
    end

    if KanbanQuery.redmineup_tags_installed
      api[:tags] = format_issue_tags(issue)
    end


    journals = issue.visible_journals_with_index
    api[:journals] = []
    journals.each do |journal|
      journal_model = {
        id: journal.id,
        user: journal.user.nil? ? nil : { id: journal.user_id, name: journal.user.name },
        notes: journal.notes,
        created_on: journal.created_on,
        private_notes: journal.private_notes,
        details: []
      }
      journal.visible_details.each do |detail|
        journal_model[:details] << {
          property: detail.property,
          name: detail.prop_key,
          old_value: detail.old_value,
          new_value: detail.value
        }
      end
      api[:journals] << journal_model
    end
    api[:custom_fields] = format_all_custom_fields issue
    api
  end

  def format_custom_fields(values)
    all = []
    values.each_with_index do |value, i|
      item =
      {
        :name => value.custom_field.name,
        :id => value.custom_field.id,
        :field_format => value.custom_field.field_format,
        :editable => value.custom_field.editable,
        :value => value.value,
        :required => value.custom_field.is_required
      }
      if value.custom_field.field_format == "list"
        item[:possible_values] = value.custom_field.possible_values
      end

      all << item
    end
    all
  end

  def format_all_custom_fields(issue)

    values = issue.visible_custom_field_values.reject {|value| value.custom_field.full_width_layout?}
    all = format_custom_fields(values)

    values = issue.visible_custom_field_values.select {|value| value.custom_field.full_width_layout?}
    all += format_custom_fields(values)
    all
  end


  def format_issue_parent(issue)
    {
      :parent_id => issue.parent_issue_id,
      :parent_name => Issue.find_by(:id=> issue.parent_issue_id).nil? ? "" : Issue.find_by(:id=> issue.parent_issue_id).subject
    }
  end

  def format_issue_tags(issue)
    if issue.respond_to?(:tag_list) && issue.respond_to?(:tag_counts) && issue.tag_list.present?
      require 'digest/md5'
      tags = []
      issue.tag_counts.collect do |t|
        i = {}
        i[:name] = t.name
        i[:color] = "##{Digest::MD5.hexdigest(t.name)[0..5]}" if RedmineupTags.settings['issues_use_colors'].to_i > 0
        tags << i
      end
      tags
    end
  end

  def available_statuses_tags(query)
    tags = ''.html_safe
    query.available_statuses.each do |status|
       tags << content_tag('label', check_box_tag('s[]', status.id, query.has_status?(status.id), :id => status.name.to_s) + " #{status.name.to_s}", :class => 'inline')
    end
    tags
  end
  
  def available_kanban_columns_tags(query)
    # p query.available_columns
    tags = ''.html_safe
    query.available_board_columns.each do |column|
      tags << content_tag('label', check_box_tag('c[]', column.name.to_s, query.has_column?(column), :id => nil) + " #{column.caption}", :class => 'inline')
    end
    tags
  end


  def to_arr(query)
    return {:query_id => query.id } if query.id
    f = []
    op = {}
    v = {}
    if query.filters.present?
      query.filters.each do |field, filter|
        f << field
        op[field.to_s] = filter[:operator]
        v[field] = []
        filter[:values].each do |value|
          v[field] << value
        end
      end
    end

    r = {:set_filter => "1",
         :sort => query.sort_criteria.to_param,
         :f => f,
         :op =>op,
         :v => v,
         :group_by => query.group_by,
         :c => query.columns.map{|c| c.name},
         :s => query.statuses
    }
  end

end
