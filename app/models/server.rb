require 'csv'
class Server < ActiveRecord::Base
  validates_presence_of :hostname, :interval_hours, :keep_snapshots, :ssh_port, :backup_server, :path
  validates_uniqueness_of :hostname
  validates_inclusion_of :window_start, :in => 0..23,
         :message => 'Should be a valid hour! Ranging from 0 to 23',
         :unless => Proc.new { |server| server.window_start.blank?  }
  validates_inclusion_of :window_stop, :in => 0..23,
         :message => 'Should be a valid hour! Ranging from 0 to 23',
         :unless => Proc.new { |server| server.window_stop.blank?  }
	validates_presence_of :comment, :unless => Proc.new { |s| s.backup_server_id == nil || s.enabled == true },
				 :message => 'You must enter a ticket number in the comment field when you disable a backup.'
  validates_inclusion_of :retention_weeks, :in => 1..26,
         :message => 'Should be a valid number of weeks! Ranging from 1 to 26',
         :unless => Proc.new { |server| server.retention_days.to_i == 0 }
  validates_inclusion_of :retention_months, :in => 0..24,
         :message => 'Should be a valid number of months! Ranging from 0 to 24',
         :unless => Proc.new { |server| server.retention_days.to_i == 0 }

  has_many :profilizations, :dependent => :destroy
  has_many :profiles, :through => :profilizations, :include => [:includes, :excludes, :splits]
  has_many :problems, :dependent => :destroy
  has_many :backup_jobs, :dependent => :destroy
  has_many :quirk_details, :dependent => :destroy
  has_many :quirks, :through => :quirk_details
  belongs_to :backup_server
  belongs_to :user
  before_save :sanitize_inputs
  accepts_nested_attributes_for :quirk_details, :allow_destroy => true
  after_initialize :set_default_values
  # For compatibility with ancient json consumers
  self.include_root_in_json = true

  def exclusive_profile
    if profile = profiles.select{|p| p.exclusive?}[0]
      return profile
    else
      return profiles.create!(:name => self.hostname, :exclusive => true)
    end
  end

  def set_default_values
    return unless new_record?
    self.ssh_port = 22 unless self.ssh_port
    self.path = '/' unless self.path
    self.interval_hours=24 unless self.interval_hours
    self.keep_snapshots = 21 unless self.keep_snapshots
    self.retention_days = 0 unless self.retention_days
    self.retention_weeks = 0 unless self.retention_weeks
    self.retention_months = 0 unless self.retention_months
  end

  def previous_jobs
    backup_jobs.all(:order => 'created_at ASC')
  end

  def last_job_status
    return nil unless backup_jobs.size > 0
    backup_jobs.last.status
  end

  def latest_problems
    problems.all(:order => 'created_at DESC', :limit=>10, :include => :backup_server)
  end

  def latest_jobs(offset = 0)
    count = (self.keep_snapshots * 1.5).to_i
    offset = 0 if offset < 0
    count = 10 if count < 10
    backup_jobs.all(:order => 'created_at DESC', :limit => count, :include => :backup_server, :offset => offset)
  end

  def to_s
    hostname
  end

  def backup_running?
    return false if self.backup_jobs.size == 0
    return true if self.backup_jobs.queued.size > 0
    return true if self.backup_jobs.running.size > 0
    false
  end

  def should_backup?
    return false unless enabled
    return false unless backup_server
    return false if backup_running?
    return false unless in_backup_window?
    interval_passed?
  end

  def in_backup_window?
    start = window_start || 0
    stop = window_stop || 0
    now = Time.new
    stop < start ? endday=now.tomorrow : endday = now
    endday = endday.strftime('%Y-%m-%d')
    start  = Time.parse( start == 0 ? "00:00" : "#{start}:00").to_i
    ending = Time.parse( stop == 0 ? "#{endday} 23:59" : "#{endday} #{stop}:00").to_i
    (start..ending).include? now.to_i
  end

  def excludes
    self.profiles.map{ | p | p.excludes.map{|e| e.path} }.flatten
  end

  def rsync_excludes
    excludes.map { | e | "--exclude=#{e}"}.join(" ")
  end

  def includes
    self.profiles.map{ | p | p.includes }.flatten
  end

  def rsync_includes
    includes.map { | i | "--include=#{i}"}.join(" ")
  end

  def splits
    self.profiles.map{ | p | p.splits }.flatten
  end

  def rsync_protects
    splits.map { | split | "--filter='protect " + split.to_s + "'"}.join(" ")
  end

  def rsync_split_excludes
    splits.map { | e | "--exclude=#{e}"}.join(" ")
  end

  def interval_passed?
    return true if last_started.nil?
    now = Time.new
    next_backup = last_started + (interval_hours * 3600)
    now > next_backup
  end

  def last_backup
    return nil if self.backup_jobs.size == 0
    self.previous_jobs.last.updated_at
  end

  def last_started
    return nil if self.backup_jobs.size == 0
    self.previous_jobs.last.created_at
  end

  def connect_address
    self.connect_to.blank? ? self.hostname : self.connect_to
  end

  def startdir
    self.path || '/'
  end

  def report(result, job)
  end

  def current_snapshots
    (self.snapshots || '').split(',')
  end

  def queue_backup
    backup_jobs.create(:backup_server => self.backup_server, :status => 'queued')
  end

  def cleanup_old_jobs
    offset = (keep_snapshots * 6).to_i + 4
    offset = 0 if offset < 0
    count = backup_jobs.all.size - offset
    if (count > 0)
      backup_jobs.all(:order => 'created_at DESC', :offset => offset, :limit => count).each do | job |
        job.destroy
      end
    end
  end

  def sanitize_inputs
    self.hostname.gsub!(/\s/,'')
    self.connect_to.gsub!(/\s/,'') unless connect_to.blank?
    self.path.gsub!(/\s/,'')
  end

  def self.to_csv(selection)
    CSV.generate(:col_sep => ';') do |csv|
      column_names = Server::column_names
      csv << column_names
      selection.each do |server|
        csv << server.attributes.values_at(*column_names)
      end
    end
  end

end
