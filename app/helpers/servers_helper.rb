module ServersHelper
  def display_retention(server)
    if server.retention_days.to_i > 0
      days = server.retention_days.to_i + server.retention_weeks.to_i * 7 + server.retention_months.to_i * 31
      "#{server.retention_days.to_i} daily, #{server.retention_weeks.to_i} weekly, #{server.retention_months.to_i} monthly (#{days} days total)"
    else
      server.keep_snapshots.to_s
    end
  end
end
