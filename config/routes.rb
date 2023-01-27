# frozen_string_literal: true

get '/projects/:project_id/kanban/board', to: 'kanban#index', as: 'project_kanban_board'

scope 'kanban' do
  get '/board', to: 'kanban#index', as: 'common_kanban_board'
  post '/set_issue_status/', to: 'kanban#set_issue_status'
  post '/:project_id/set_issue_status/', to: 'kanban#set_issue_status'
  post '/issues/', to: 'kanban#get_issues'
  # get '/:project_id/issues/', to: 'kanban#get_issues'
  post '/:project_id/issues/', to: 'kanban#get_issues'
  get '/issue/:id', to: 'kanban#get_issue'
  post '/:project_id/order/', to: 'kanban#set_sort_order'
  post '/order/', to: 'kanban_pro#set_sort_order'
  patch '/issue/:id', to: 'kanban_pro#patch'
end

scope 'questionlist' do
  get '/:issue_id', to: 'questionlist#index'
  post '/:issue_id', to: 'questionlist#create'
  put '/assign/:id', to: 'questionlist#assign'
  patch '/:id', to: 'questionlist#patch'
end

scope 'question' do
  get '/:questionlist_id', to: 'question#index'
  get '/assignees/:issue_id', to: 'question#assignees'
  post '/:questionlist_id', to: 'question#create'
  patch '/:id', to: 'question#patch'
end

get '/question/get_issue_users/:issue_id', to: 'question#get_issue_users'

post '/kanban/:issue_id/checklist', to: 'checklist#index'

# get '/query/new', to: 'kanban_query#new'
scope 'kanban_query' do
  get '/new', to: 'kanban_query#new', as: 'kanban_query_new'
  get '/edit/:id', to: 'kanban_query#edit', as: 'kanban_query_edit'
  post '/create', to: 'kanban_query#create', as: 'kanban_query_create'
  patch '/:id', to: 'kanban_query#update', as: 'kanban_query_update'
  put '/:id', to: 'kanban_query#update', as: 'kanban_query_put'
end

