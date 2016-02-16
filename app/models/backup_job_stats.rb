class BackupJobStats < ActiveRecord::Base
  belongs_to :backup_job

  def process_stats
    parse_all
    created_at = backup_job.created_at
  end

  def parse_all
    backup_job.commands.each do |cmd|
      if %w(main_rsync split_rsync).include? cmd.label
        output = cmd.output
        parse(output) if output
        bump :time_rsync, command_time_diff(cmd)
      elsif %w(snapshot remove_snapshot).include? cmd.label
        bump :time_snap, command_time_diff(cmd)
      else
        bump :time_other, command_time_diff(cmd)
      end
    end
  end

  def parse(rsync_output)
    buf = rsync_output.dup
    buf.gsub!(/,/, '') # Recent rsync uses thousands-comma's. We strip them.
    buf.split(/\n/).each do |line|
      # Number of files: 77,503 (reg: 63,162, dir: 10,528, link: 3,809, special: 4)
      if /Number of files: (\d+)/.match(line)
        bump :inodes, $1
        bump :n_reg, $1 if /reg: (\d+)/ =~ line
        bump :n_dir, $1 if /dir: (\d+)/ =~ line
        bump :n_lnk, $1 if /link: (\d+)/ =~ line
        bump :n_spc, $1 if /special: (\d+)/ =~ line
      end
      # Number of created files: 0
      if /Number of created files: (\d+)/.match(line)
        bump :n_cre, $1
      end
      # Number of regular files transferred: 33
      # Number of files transferred: 72
      if /Number of (?:regular )?files transferred: (\d+)/.match(line)
        bump :n_xfr, $1
      end
      # Total file size: 2,820,109,491 bytes
      if /Total file size: (\d+)/.match(line)
        bump :current_size, $1
      end
      # Total transferred file size: 17,610,579 bytes
      # Literal data: 17,610,579 bytes
      if /Total transferred file size: (\d+)/.match(line)
        bump :xfr_size, $1
      end
      # Matched data: 0 bytes
      # File list size: 744,171
      if /File list size: (\d+)/.match(line)
        bump :list_size, $1
      end
      # File list generation time: 0.001 seconds
      if /File list generation time: ([.0-9]+)/.match(line)
        bump :list_time, $1.to_f
      end
      # File list transfer time: 0.000 seconds
      if /File list transfer time: ([.0-9]+)/.match(line)
        bump :list_time, $1.to_f
      end
      # Total bytes sent: 11,548
      if /Total bytes sent: (\d+)/.match(line)
        bump :net_sent, $1
      end
      # Total bytes received: 7,011,653
      if /Total bytes received: (\d+)/.match(line)
        bump :net_recv, $1
      end
    end
    self
  end

  private
  def bump(key, value)
    oldvalue = self.attributes[key.to_s] || 0

    if value.class == String
      self.attributes = { key => oldvalue + value.to_i }
    else
      self.attributes = { key => oldvalue + value }
    end
  end

  def command_time_diff(c)
    return 0 unless c.created_at and c.updated_at
    (c.updated_at - c.created_at).round
  end
end
