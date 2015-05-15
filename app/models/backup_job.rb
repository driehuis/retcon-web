class BackupJob < ActiveRecord::Base
  attr_accessor :start_now
  belongs_to :server
  belongs_to :backup_server
  has_many :commands, :dependent => :destroy
  has_one :backup_job_stats

  named_scope :running, :conditions => {:finished => false}, :order => 'updated_at DESC', :include => [:server]
  named_scope :queued, :conditions => {:status => 'queued'}, :order => 'created_at ASC', :include => [:server, :backup_server]
  named_scope :latest_problems, :conditions => "status NOT IN ('OK','running','queued', 'done')", :order => 'updated_at DESC', :limit => 20, :include => [:server]

  def fs
    self.backup_server.zpool + '/' + self.server.hostname
  end

  def prepare_fs
     run_command("/sbin/zfs list #{self.fs}", "fs_exists")
  end

  def finish
    self.finished = true
    save
  end

  def run
    self.status = 'running'
    self.started = Time.now
    self.finished = false
    save
    prepare_fs
  end

  def display_status
    if self.status == 'queued'
      'queued'
    elsif self.finished == false
      'running'
    else
      self.status
    end
  end

  def ssh_command
    "ssh -c arcfour -p #{self.server.ssh_port}"
  end

  def main_rsync
    "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    server.rsync_protects + " " + server.rsync_includes + " " +
    server.rsync_split_excludes + " " + server.rsync_excludes +
    " #{self.server.connect_address}:#{self.server.startdir} /#{fs}/"
  end

  def rsync_template
    "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e '#{ssh_command}' " +
    server.rsync_protects + " " + server.rsync_includes + " " +
    server.rsync_excludes +
    " #{self.server.connect_address}:DIR /#{fs}/"
  end

  def rsyncs
    if stored_rsyncs.blank? and !self.last_rsync
      populate_rsyncs
    end
    self.stored_rsyncs.split('!RSYNC!')
  end

  def populate_rsyncs
    syncs = get_rsyncs
    self.stored_rsyncs=syncs
    save
  end

  def get_rsyncs
    self.server.splits.reject{|s| server.excludes.include? s.path }.map do | split |
      arr = []
      split_dir = self.server.startdir + split.path
      arr.concat(('a'..'z').to_a)
      arr.concat(('A'..'Z').to_a)
      arr.concat((0..9).to_a)
      to_rsync = []
      split.depth.times do |n|
        if n == 0
          to_rsync = arr.map{|i| "#{i}*"}
        else
          to_rsync = to_rsync.map{|i| arr.map{|j| "#{i}/#{j}*"}}.flatten
        end
      end
      to_rsync.map{|letter| rsync_template.sub('DIR', split_dir + "/#{letter}") }
    end.flatten.join('!RSYNC!')
  end

  def code_to_success(num, output='')
    return "OK" if [0,24].include?(num)
    return "FAIL" if [12,30,127].include?(num)
    return "FAIL" if Regexp.new(/Command not found/).match(output)
    return "FAIL" if Regexp.new(/Input\/output error \(5\)/).match(output)
    return "FAIL" if Regexp.new(/IO error encountered/).match(output)
    if match = Regexp.new(/\((\d+) bytes received so far\)/).match(output)
      return "FAIL" if match[1].to_i == 0
    end
    return "PARTIAL"
  end

  def run_command(command, label)
    command += ' 2>&1'
    commands.create!(:command => command, :label => label, :user => backup_server.user)
  end

  def wakeup
    last = commands.last
    if last && last.exitstatus
      run_callback(last)
    end
  end

  def run_callback(command)
    args = command.label.split(/ /)
    method = args.delete_at(0)
    send('after_' + method, command, *args)
  end

  def after_fs_exists(command)
    if command.exitstatus == 0
      if server.remove_only?
        cleanup
      else
        start_rsyncs
      end
    else
      if server.remove_only?
        cleanup
      else
        run_command("/bin/pfexec /sbin/zfs create #{self.fs}", "create_fs")
      end
    end
  end

  def after_create_fs(command)
    if command.exitstatus == 0
      run_command("/sbin/zfs list #{self.fs}", "fs_exists_confirm")
    else
      self.status = 'Unable to create filesystem'
      self.finished = true
      save
    end
  end

  def after_fs_exists_confirm(command)
    if command.exitstatus == 0
      start_rsyncs
    else
      self.status = 'Unable to create filesystem'
      self.finished = true
      save
    end
  end

  def start_rsyncs
    run_command(self.main_rsync, "main_rsync")
  end

  def after_main_rsync(command)
    self.status = code_to_success(command.exitstatus, command.output)
    save
    run_split_rsyncs
  end

  def run_split_rsyncs
    if rsync = get_first_rsync
      run_command(rsync, "split_rsync")
    else
      if self.status == 'FAIL'
        finish
      else
        do_snapshot
      end
    end
  end

  def get_first_rsync
    stored = rsyncs
    self.last_rsync = true if stored.size == 1
    command = stored.first
    stored.delete_at 0
    self.stored_rsyncs = stored.join('!RSYNC!')
    save
    command
  end

  def do_snapshot
    run_command("/bin/pfexec /sbin/zfs snapshot #{self.fs}@#{self.updated_at.to_i}", "snapshot")
  end

  def after_snapshot(command)
    cleanup
  end

  def after_split_rsync(command)
    run_split_rsyncs
  end

  def cleanup
    server.cleanup_old_jobs
    remove_old_snapshots
  end

  def run_get_snapshots
    run_command("/sbin/zfs list -H -r -o name -t snapshot #{self.fs} | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
  end

  # The snapshot age code requires snapshots to be named according to a
  # seconds_after_epoch naming scheme. Retcon generates such names, external
  # tools might not. This algorithm refuses to clean up ill-named snapshots
  # and returns nil
  ONEDAY = 24 * 3600
  BRACKETS = 0 .. 2
  BRACKET_DAYS = [ 1, 7, 30 ]
  def find_snapshot_to_delete(names)
    # First, check the snapshot names for sanity.
    return nil if names.select{|x| !/^\d+$/.match(x)}.size > 0

    brackets = []
    bracket_maxage = []
    snaps = names.map{|x| x.to_i}
    bracket_retention = [ server.retention_days.to_i, server.retention_weeks.to_i, server.retention_months.to_i ]
    last_maxage = 0

    BRACKETS.each do |bracket|
      bracket_maxage[bracket] = ONEDAY * BRACKET_DAYS[bracket] * bracket_retention[bracket]
      bracket_maxage[bracket] += last_maxage
      last_maxage = bracket_maxage[bracket]
      brackets[bracket] = []
    end

    # Assign each snapshot to a bracket of time.
    latest = snaps.sort.max
    snaps.sort.each do |snap|
      age = latest - snap
      out_of_range = true
      BRACKETS.each do |bracket|
        if age < bracket_maxage[bracket]
          brackets[bracket] << snap
          out_of_range = false
          break
        end
      end
      if out_of_range
        # If the snapshot is in none of the brackets, we have our best candidate!
        t1 = Time.at(snap).strftime("%F %H:%M")
        logger.debug "selecting snapshot #{snap} #{t1}: out of range"
        return snap.to_s
      end
    end

    BRACKETS.each do |bracket|
      if brackets[bracket].size == 0
        logger.debug "bracket #{bracket} is empty"
      else
        count=brackets[bracket].size
        t1 = Time.at(brackets[bracket].first).strftime("%F %H:%M")
        t2 = Time.at(brackets[bracket].last).strftime("%F %H:%M")
        logger.debug "bracket #{bracket}: #{count} entries from #{t1} to #{t2}"
      end
    end

    # No snapshots are completely out of range. For each bracket,
    # see if we have too many snapshots in that bracket. If we do,
    # we select the one with the smallest time difference to its
    # successor (and eventual replacement).
    # Exception: we never select the oldest snapshot in a bracket.
    candidate = nil
    BRACKETS.each do |bracket|
      if brackets[bracket].size > bracket_retention[bracket]
        previous = nil
        min_time_diff = nil
        first_candidate = true
        brackets[bracket].each do |snap|
          if previous
            time_diff = snap - previous
            if !min_time_diff || min_time_diff >= time_diff
              min_time_diff = time_diff
              candidate = first_candidate ? snap : previous
            end
            first_candidate = false
          end
          previous = snap
        end
      end
    end
    if candidate
      t1 = Time.at(candidate).strftime("%F %H:%M")
      logger.debug "selecting snapshot #{candidate} #{t1}: least time difference"
    end
    candidate ? candidate.to_s : nil
  end

  def remove_old_snapshots
    snaps = server.current_snapshots
    if server.remove_only?
      self.status = 'OK'
      save
      if snaps.size == server.keep_snapshots
        server.keep_snapshots -= 1
        server.save # next snapshot will vanish on the next run
        run_get_snapshots
      elsif snaps.size == 0
        run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}", "remove_fs")
      else
        snap = snaps.delete_at(0)
        run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}@#{snap}", "remove_snapshot #{snap}")
        server.snapshots = snaps.join(',')
        server.save
      end
    elsif server.retention_days.to_i > 0
      if snap = find_snapshot_to_delete(snaps)
        run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}@#{snap}", "remove_snapshot #{snap}")
        server.snapshots = snaps.select{|s| s != snap}.join(',')
        server.save
      else
        run_get_snapshots
      end
    elsif snaps.size > server.keep_snapshots
      snap = snaps.delete_at(0)
      run_command("/bin/pfexec /sbin/zfs destroy #{self.fs}@#{snap}", "remove_snapshot #{snap}")
      server.snapshots = snaps.join(',')
      server.save
    else
      run_get_snapshots
    end
  end

  def after_remove_snapshot(command, snap)
    remove_old_snapshots
  end

  def after_diskusage(command)
    self.server.usage = command.output.to_i
    self.server.save
    run_command("/sbin/zfs get -Hp available,used #{self.backup_server.zpool} | awk '{print $3}'", "backupserver_diskspace")
  end

  def after_get_snapshots(command)
    snapshots = command.output.split(/\n/).join(',') rescue ''
    self.server.snapshots = snapshots
    self.server.save
    run_command("/sbin/zfs get -Hp used #{self.fs} | /usr/gnu/bin/awk '{print $3}'", "diskusage")
  end

  def after_backupserver_diskspace(command)
    @string = command.output
    @free_used = @string.split("\n")
    self.backup_server.disk_free = @free_used[0].to_i
    self.backup_server.disk_used = @free_used[1].to_i
    self.backup_server.disk_size = self.backup_server.disk_free + self.backup_server.disk_used

    self.backup_server.save
    finish
  end

  def after_remove_fs(command)
    finish
    self.server.destroy
  end
end
