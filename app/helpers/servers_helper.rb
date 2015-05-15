module ServersHelper
  def display_retention(server)
    if server.retention_days.to_i > 0
      "#{server.retention_days.to_i} daily, #{server.retention_weeks.to_i} weekly, #{server.retention_months.to_i} monthly"
    else
      server.keep_snapshots.to_s
    end
  end
end
