module TranslationHelper





  def build_translations
    all = [
           :label_personal_checklist, :label_personal_checklist_plural,
           :label_checklist, :label_checklist_plural,
           :button_add,
           :button_cancel,
           :button_create,
           :button_save,
           :button_edit,
           :button_delete,
           :button_submit,


           :label_assign_to_me,
           :label_comment_plural,

           :label_spent_time,

           :label_project,

           :button_log_time,
           :label_search,
           :label_today,
           :label_ago,
           :label_related_issues,
           :field_total_estimated_hours,
           :text_are_you_sure,
           :label_attachment_plural,
           :label_attachment,
           :label_edit_attachments,
           :button_download,

           :field_is_private, :field_start_date, :field_parent_issue, :field_name, :field_type, :field_estimated_hours,:field_due_date, :field_description, :field_priority, :field_status, :field_assigned_to, :field_updated_on,

           :label_history,

           :label_day_plural,
           :label_string,
           :label_added_time_by,
           :label_updated_time,
           :field_filename,
           :label_issue_history_notes,

           :showIsDone, :hideIsDone,
           :copyText,

           :addDeadline, :editDeadline,

           # :label_comment_add,
           :editComment, :removeComment,
           :button_reply,
           :answer_from,

           :removeAssignee,
           :actionview_instancetag_blank_option,

           # :label_attachment_new,
           :label_item_position,


           :label_board_locked,
           :label_no_data,

           :setting_attachment_max_size,
           :setting_attachment_extensions_denied,
           :setting_attachment_extensions_allowed,

           :createChecklistTemplate,   :areYouSureToAddTemplate, :listOfTemplates, :createTemplate, :checklistElements, :bindTemplateToProject,

           :notice_issue_update_conflict,

           :label_assigned_to_me_issues,
           :label_add_checklists_from_template,
           :label_new_personal_checklist,
           :label_new_checklist,
           :label_subtask_plural,
           :info_my_tasks_button, :info_locked_button,

           :errors_error,
    ]

    @translations = {}
    all.each do |label|
      @translations[label] = I18n.t(label)
    end
    @translations.to_json
  end

end
