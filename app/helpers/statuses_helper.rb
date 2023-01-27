module StatusesHelper
  def format_statuses(items, board_statuses)
    data = []
    mapper = {}
    board_statuses = [] if board_statuses.nil?

    items.each do |item|
      board_status = board_statuses.find { |el| el[:id] == item.id }

      is_visible = true
      wip = 0
      unless board_status.nil?
        is_visible = board_status[:is_visible]
        wip = board_status.key?(:wip) ? board_status[:wip] : 0
      end

      status = {
        id: item.id,
        name: item.name,
        color: Setting.plugin_redmine_kanban["status_color_#{item.id}"],
        is_closed: board_status.nil? ? item.is_closed : board_status[:is_closed],
        is_visible: is_visible,
        is_group: false,
        wip: wip,
        substatuses: [],
        position: item.position
      }

        data.insert(item.id, status)


    end

    data.select { |el| el }.sort_by { |el| el[:position] }
  end
end