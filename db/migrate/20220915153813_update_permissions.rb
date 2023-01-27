class UpdatePermissions < ActiveRecord::Migration[5.2]

  def change
    Setting.load_plugin_settings
    Setting.plugin_redmine_kanban = {'kanban_show_in_app_menu' => 1, 'kanban_show_in_top_menu' => 1}

    say_with_time "add project module Kanban & Checklists to defaults" do
      Setting.default_projects_modules += ['kanban', 'checklists']
    end

    # Enable Rate for every project.
    say_with_time "enable modules Kanban & Checklists for existing project" do
      projects = Project.all.to_a

      projects.each do |project|
        project.enable_module!(:kanban)
        project.enable_module!(:checklists)
      end

      projects.length
    end
  end


end