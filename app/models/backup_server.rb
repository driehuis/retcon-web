class BackupServer < ActiveRecord::Base
  has_many :servers
  has_many :backup_jobs, :dependent => :destroy
  has_many :problems, :dependent => :destroy
  has_one :user

  validates_presence_of :hostname, :zpool, :max_backups
  before_save :sanitize_inputs

  attr_accessor :in_subnet

  def server_count
      servers.count
  end

  def running_backup_count
      running_backups.count
  end

  def queued_backup_count
      queued_backups.count
  end

  def to_xml(options={})
    options.merge!(:methods => [ :server_count, :running_backup_count, :queued_backup_count ])
    super(options)
  end

  def self.user_missing
    self.all.select { | b | b.user.nil? }
  end

  def latest_problems
    problems.all(:order => 'created_at DESC', :limit=>10, :include => [:server])
  end

  def latest_jobs
    backup_jobs.where("NOT status = 'queued'", :include => [:server]).order('updated_at DESC')
  end

  def to_s
    hostname
  end

  def should_start
    self.servers.select { | server | server.should_backup? }
  end

  def should_queue
    should_start.select do | server |
      server.backup_jobs.size == 0 || server.backup_jobs.last.status != 'queued'
    end
  end

  def queue_backups
    should_queue.each do | server |
      BackupJob.create!(:backup_server => self, :server => server, :status => 'queued')
    end
  end

  def queued_backups(opts={})
    backup_jobs.all({:conditions => { :status => 'queued'}, :order => 'created_at ASC' }.merge(opts))
  end

  def next_queued
    count = self.max_backups - self.running_backups.size
    count = 0 if count < 0
    queued_backups :limit => count
  end

  def running_backups
    backup_jobs.all(:conditions => { :finished => false })
  end

  def start_queued
    next_queued.each do | job |
      job.run
    end
  end

  def sanitize_inputs
    self.hostname.gsub!(/\s/,'')
    self.zpool.gsub!(/\s/,'')
  end
end
