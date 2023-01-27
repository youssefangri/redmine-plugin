

require 'redmine'

Redmine::Plugin.register :redmine_kanban do
  name 'Redmine Kanban plugin'
  author 'Roman'
  description 'This is a plugin for Redmine'
  version '1.2.0'
  url 'https://redmine-kanban.com/'
  author_url 'https://redmine-kanban.com/'

  project_module :kanban do
    permission :view_kanban, {:kanban => [:index, :get_issues, :get_issue, :set_issue_status ], :kanban_query => [:index], :kanban_reports => [:index] }
    permission :save_queries_kanban, {:kanban_query => [:new, :create, :edit, :update, :destroy]}, require: :loggedin
  end

  project_module :checklists do
    permission :edit_checklists, { :questionlist => [:create, :update, :delete] }
  end

  menu :project_menu, :kanban, { controller: 'kanban', action: 'index' }, caption: :label_kanban, after: :issues, param: :project_id
  menu :top_menu, :kanban, { controller: 'kanban', action: 'index', :project_id => nil }, caption: :label_kanban, first: true ,
        :if => Proc.new{ User.current.allowed_to?({:controller => 'kanban', :action => 'index'}, nil, {:global => true}) && Setting.plugin_redmine_kanban['kanban_show_in_top_menu'].to_i > 0  }

  menu :application_menu, :redmine_kanban, { controller: 'kanban', action: 'index' }, caption: :label_kanban, 
        :if => Proc.new{ User.current.allowed_to?({:controller => 'kanban', :action => 'index'}, nil, {:global => true})  && Setting.plugin_redmine_kanban['kanban_show_in_app_menu'].to_i > 0 }

  menu :admin_menu, :redmine_kanban, {controller: 'settings', action: 'plugin', id: 'redmine_kanban'}, caption: :label_kanban, html: {class: 'icon'}

  settings :default => {:empty => true}, :partial => 'settings/kanban/index'

end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end

require File.dirname(__FILE__) + '/lib/redmine_kanban'
