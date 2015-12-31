require 'spec_helper'
require 'time'

describe Server do
  before(:each) do

  end

  it "should create a new instance given valid attributes" do
    s = FactoryGirl.build(:server)
    s.valid?.should be true
  end

  it "should not be valid when no hostname is given" do
    s = FactoryGirl.build(:server)
    s.hostname = nil
    s.valid?.should be false
  end

  it "should not be valid when no interval is given" do
    s = FactoryGirl.build(:server)
    s.interval_hours = nil
    s.valid?.should be false
  end

  it "should not be valid when no ssh_port is given" do
    s = FactoryGirl.build(:server)
    s.ssh_port = nil
    s.valid?.should be false
  end

  it "should not be valid when no keep_snapshots is given" do
    s = FactoryGirl.build(:server)
    s.keep_snapshots = nil
    s.valid?.should be false
  end

  it "should default to keep_snapshots=21" do
    s = FactoryGirl.build(:server)
    expect(s.keep_snapshots).to be == 21
  end

  it "should honor initializing keep_snapshots" do
    s = FactoryGirl.build(:server, :keep_snapshots => 20)
    expect(s.keep_snapshots).to be == 20
  end

  it "should not accept impossible hours" do
    s = FactoryGirl.build(:server)
    s.window_start = 25
    s.valid?.should be false
    s.window_start = 1
    s.window_stop = 25
    s.valid?.should be false
    s.window_stop = 2
    s.valid?.should be true
  end

  it "should be valid when the other attributes are not given" do
    s = FactoryGirl.create(:server)
    bs = FactoryGirl.create(:backup_server)
    s.connect_to = nil
    s.enabled = true
    s.backup_server_id = bs.id
    s.valid?.should be true
  end

  it "should provide a to_s method" do
    s = FactoryGirl.build(:server)
    s.to_s.should == s.hostname
  end

  it "should know if a backup is running" do
    server = FactoryGirl.create(:server)
    job = FactoryGirl.create(:backup_job, :server => server, :status => 'running', :finished => false)
    server.backup_running?.should be true
  end

  it "should know when a backup is already queued" do
    server = FactoryGirl.create(:server)
    job = FactoryGirl.create(:backup_job, :server => server, :status => 'queued')
    server.backup_running?.should be true
  end

  it "should not mark a backup as running when the status is not queued or running" do
    server = FactoryGirl.create(:server)
    job = FactoryGirl.create(:backup_job, :server => server, :status => 'OK', :finished => true)
    server.backup_running?.should be false
  end

  it "knows no backup is running when there are 0 backup jobs" do
    server = FactoryGirl.build(:server)
    server.backup_jobs.size.should == 0
    server.backup_running?.should be false
  end

  it "should always be in the backup window when no start and end is given" do
    server = FactoryGirl.build(:server)
    server.window_start = nil
    server.window_stop = nil
    server.in_backup_window?.should be true
  end

  it "should know when it's not in the window" do
    server_one_hour_window = FactoryGirl.build(:server)
    server_one_hour_window.window_start = 1
    server_one_hour_window.window_stop = 2
    Time.should_receive(:new).and_return(Time.parse("03:00"))
    server_one_hour_window.in_backup_window?.should be false

    server_23_hour_window = FactoryGirl.build(:server)
    server_23_hour_window.window_start = 0
    server_23_hour_window.window_stop = 23
    Time.should_receive(:new).and_return(Time.parse("23:30"))
    server_23_hour_window.in_backup_window?.should be false
  end

  it "should know when it's in the window" do
    server = FactoryGirl.build(:server)
    server.window_start = 1
    server.window_stop = 2
    Time.should_receive(:new).and_return(Time.parse("01:30"))
    server.in_backup_window?.should be true

    server.window_start = 0
    server.window_stop = 1
    Time.should_receive(:new).and_return(Time.parse("00:30"))
    server.in_backup_window?.should be true

    server.window_start = 23
    server.window_stop = 0
    Time.should_receive(:new).and_return(Time.parse("23:30"))
    server.in_backup_window?.should be true
  end

  it "should handle windows that cross midnight" do
    server = FactoryGirl.build(:server)
    server.window_start = 22
    server.window_stop = 2
    next_day = Time.new.tomorrow
    parsed_when = Time.parse("#{next_day.strftime('%Y-%m-%d')} 01:00")
    Time.should_receive(:new).and_return(parsed_when)
    server.in_backup_window?.should be true
  end

  it "should know when its past the interval" do
    s = FactoryGirl.create(:server, :interval_hours => 1)
    j = FactoryGirl.create(:backup_job, :created_at => (Time.new - 3601), :server => s)
    s.interval_passed?.should be true

    s.interval_hours = 3
    s.interval_passed?.should be false
  end

  it "should not backup when backups are not enabled" do
    s = FactoryGirl.build(:server, :enabled => false)
    s.should_backup?.should be false
  end

  it "should not backup when there is no backup server configured" do
    s = FactoryGirl.build(:server, :backup_server => nil)
    s.should_backup?.should be false
  end

  it "should not backup when a backup is already running" do
    s = FactoryGirl.build(:server)
    s.stub(:backup_running?).and_return true
    s.should_backup?.should be false
  end

  it "should not backup when its outside of the window" do
    s = FactoryGirl.build(:server)
    s.stub(:in_backup_window?).and_return false
    s.should_backup?.should be false
  end

  it "should not backup when the interval didnt pass" do
    s = FactoryGirl.build(:server)
    s.stub(:interval_passed?).and_return false
    s.should_backup?.should be false
  end

  it "should know when to backup" do
    s = FactoryGirl.build(:server)
    s.stub(:backup_running?).and_return false
    s.stub(:in_backup_window?).and_return true
    s.stub(:interval_passed?).and_return true
    s.should_backup?.should be true
  end

  it "should know the excludes inherited trough the profiles" do
    s = FactoryGirl.build(:server) # we need one server
    p1 = FactoryGirl.build(:profile, :name => 'linux') # profile one
    p2 = FactoryGirl.build(:profile, :name => 'standard') # and another one
    p1.excludes << FactoryGirl.build(:exclude, :path => '/') # exclude one
    p2.excludes << FactoryGirl.build(:exclude, :path => '/var/log') # second exclude
    s.profiles << p1
    s.profiles << p2
    s.excludes.size.should == 2
  end

  it "should know the includes inherited trough the profiles" do
    s = FactoryGirl.build(:server) # we need one server
    p1 = FactoryGirl.build(:profile, :name => 'linux') # profile one
    p2 = FactoryGirl.build(:profile, :name => 'standard') # and another one
    p1.includes << FactoryGirl.build(:include, :path => '/') # include one
    p2.includes << FactoryGirl.build(:include, :path => '/var/log') # second include
    s.profiles << p1
    s.profiles << p2
    s.includes.size.should == 2
  end

  it "should compile the list of excludes to valid rsync args" do
    s = FactoryGirl.build(:server) # we need one server
    p1 = FactoryGirl.build(:profile, :name => 'linux') # profile one
    p2 = FactoryGirl.build(:profile, :name => 'standard') # and another one
    p1.excludes << FactoryGirl.build(:exclude, :path => '/') # include one
    p2.excludes << FactoryGirl.build(:exclude, :path => '/var/log') # second include
    s.profiles << p1
    s.profiles << p2

    s.rsync_excludes.should == '--exclude=/ --exclude=/var/log'
  end

  it "should compile the list of includes to valid rsync args" do
    s = FactoryGirl.build(:server) # we need one server
    p1 = FactoryGirl.build(:profile, :name => 'linux') # profile one
    p2 = FactoryGirl.build(:profile, :name => 'standard') # and another one
    p1.includes << FactoryGirl.build(:include, :path => '/') # include one
    p2.includes << FactoryGirl.build(:include, :path => '/var/log') # second include
    s.profiles << p1
    s.profiles << p2

    s.rsync_includes.should == '--include=/ --include=/var/log'
  end

  it "should compile a list of splits in order to protect them" do
    s = FactoryGirl.build(:server)
    p1 = FactoryGirl.build(:profile, :name => 'linux')
    p2 = FactoryGirl.build(:profile, :name => 'standard')
    p1.splits << FactoryGirl.build(:split, :path => '/var/spool/mqueue')
    p2.splits << FactoryGirl.build(:split, :path => '/home')
    s.profiles << p1
    s.profiles << p2
    s.rsync_protects.should == "--filter='protect /var/spool/mqueue' --filter='protect /home'"
  end

  it "should compile a list of splits in order to exclude them" do
    s = FactoryGirl.build(:server)
    p1 = FactoryGirl.build(:profile, :name => 'linux')
    p2 = FactoryGirl.build(:profile, :name => 'standard')
    p1.splits << FactoryGirl.build(:split, :path => '/var/spool/mqueue')
    p2.splits << FactoryGirl.build(:split, :path => '/home')
    s.profiles << p1
    s.profiles << p2
    s.rsync_split_excludes.should == '--exclude=/var/spool/mqueue --exclude=/home'
  end

  it "should turn the snapshots property into a array" do
    s = FactoryGirl.build(:server, :snapshots => '1234,5678,90')
    s.current_snapshots.size.should == 3
    s.current_snapshots[0].should == '1234'
    s.current_snapshots[2].should == '90'
  end

  it "should queue a backup when queue_backup is called" do
    s = FactoryGirl.create(:server)
    s.backup_jobs.size.should == 0
    s.queue_backup
    s.backup_jobs.size.should == 1
    s.backup_jobs.last.status.should == 'queued'
  end

  it "scheduling should not crash on servers in remove only mode" do
    s = FactoryGirl.build(:server, :remove_only => true, :keep_snapshots => 0)
    s.last_started.should be_nil
  end

  # The original algorithm was never to keep more jobs than keep_snapshots.
  # Currently, we keep 150% of keep_snapshots, plus four. This gives us
  # some breathing room in case a backupjob makes no snapshot (for
  # example, because its rsync FAILed), so that we improve our chances to
  # retain some extra log information about failed jobs.
  # With keep_snapshots => 4, we should keep 6+4=10 backup jobs.
  it "should cleanup old backupjobs" do
    server = FactoryGirl.create(:server, :keep_snapshots => 4)
    11.times do
      FactoryGirl.create(:backup_job, :backup_server => server.backup_server, :server => server, :status => 'OK')
    end
    job = server.backup_jobs.last
    server.backup_jobs.size.should == 11
    server.cleanup_old_jobs
    server.backup_jobs.size.should == 10
  end

  it "should have a method that gets or creates an exclusive profile" do
    server = FactoryGirl.create(:server)
    p1 = FactoryGirl.create(:profile)
    server.profiles << p1
    server.profiles.count.should == 1
    p2 = server.exclusive_profile
    p2.exclusive.should == true
    server.profiles.length.should == 2
    p2.save
    p3 = server.exclusive_profile
    p3.should === p2
  end
end
