require 'spec_helper'

describe BackupJob do
  it "should build a valid main rsync command line" do
    s = FactoryGirl.build(:server, :hostname => 'server1.example.com')
    p = FactoryGirl.build(:profile, :name => 'linux')
    p.includes << FactoryGirl.build(:include, :path => '/')
    p.excludes << FactoryGirl.build(:exclude, :path => '/backup')
    p.splits << FactoryGirl.build(:split, :path => '/home')
    s.profiles << p
    j = FactoryGirl.build(:backup_job, :server => s)
    expect(j.main_rsync).to be == "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/home --exclude=/backup server1.example.com:/ /backup/server1.example.com/"
  end

  it "should store a list of rsyncs" do
    s = FactoryGirl.build(:server, :hostname => 'server1.example.com')
    p = FactoryGirl.build(:profile, :name => 'linux')
    p.includes << FactoryGirl.build(:include, :path => '/')
    p.excludes << FactoryGirl.build(:exclude, :path => '/backup')
    p.splits << FactoryGirl.build(:split, :path => '/home')
    s.profiles << p
    j = FactoryGirl.build(:backup_job, :server => s)
    j.rsyncs.size.should == 62 # a-z,A-Z,0-9
    j.rsyncs.first.should == "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup server1.example.com://home/a* /backup/server1.example.com/"
    j.rsyncs.last.should == "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup server1.example.com://home/9* /backup/server1.example.com/"
  end

  it "should store more rsyncs if the depth is 2" do
    s = FactoryGirl.build(:server, :hostname => 'server1.example.com')
    p = FactoryGirl.build(:profile, :name => 'linux')
    p.includes << FactoryGirl.build(:include, :path => '/')
    p.excludes << FactoryGirl.build(:exclude, :path => '/backup')
    p.splits << FactoryGirl.build(:split, :path => '/home', :depth => 2)
    s.profiles << p
    j = FactoryGirl.build(:backup_job, :server => s)
    j.rsyncs.size.should == 3844 # a-z,A-Z,0-9
    j.rsyncs.first.should == "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup server1.example.com://home/a*/a* /backup/server1.example.com/"
    j.rsyncs.last.should == "/usr/bin/pfexec rsync --stats -aHRW --numeric-ids --timeout=3600 --delete-excluded --exclude=.zfs -e 'ssh -c arcfour -p 22' --filter='protect /home' --include=/ --exclude=/backup server1.example.com://home/9*/9* /backup/server1.example.com/"
  end

  it "should not add splits if there is a matching include" do
    s = FactoryGirl.build(:server, :hostname => 'server1.example.com')
    p = FactoryGirl.build(:profile, :name => 'linux')
    p.includes << FactoryGirl.build(:include, :path => '/')
    p.excludes << FactoryGirl.build(:exclude, :path => '/home')
    p.splits << FactoryGirl.build(:split, :path => '/home')
    s.profiles << p
    j = FactoryGirl.build(:backup_job, :server => s)
    j.rsyncs.size.should == 0
  end

  it "should have a method to convert exit statusses to a string representation" do
    job = FactoryGirl.build(:backup_job)
    job.code_to_success(0).should == 'OK'
    job.code_to_success(12, 'rsync: Command not found').should == 'FAIL'
    job.code_to_success(127).should == 'FAIL'
    job.code_to_success(12, 'rsync: connection unexpectedly closed (0 bytes received so far)').should == 'FAIL'
    job.code_to_success(25).should == 'PARTIAL'
  end

  it "should have a method for finishing" do
    job = FactoryGirl.build(:backup_job)
    job.finished.should_not be true
    job.finish
    job.finished.should == true
  end

  it "should create commands with a specific label" do
    job = FactoryGirl.create(:backup_job)
    job.run_command('ls', 'listing')
    job.commands.size.should be 1
    job.commands.last.label.should == 'listing'
    job.commands.last.command.should == 'ls 2>&1'
  end

  it "should create commands for the right user" do
    job = FactoryGirl.create(:backup_job)
    job.run_command('ls', 'listing')
    job.commands.last.user.should == job.backup_server.user
  end

  it "should pull the database for commands to pick up and run the callback" do
    job = FactoryGirl.create(:backup_job)
    command = FactoryGirl.create(:command, :backup_job => job)
    #job.should_receive(:run_callback).once.with(command)
    expect(job).to receive(:run_callback).once.with(command)
    job.wakeup
  end

  it "it should not run the callback when the command has no exitstatus" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :backup_job => job, :exitstatus => nil)
    #job.should_not_receive(:run_callback).with(command)
    expect(job).not_to receive(:run_callback).with(command)
    job.wakeup
  end

  it "should call the right method when being called back" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :label => 'snapshot')
    #job.should_receive(:after_snapshot).with(command)
    expect(job).to receive(:after_snapshot).with(command)
    job.run_callback(command)
  end

  it "should parse the rest of the label as command args" do
    job = FactoryGirl.create(:backup_job)
    command = FactoryGirl.create(:command, :label => 'remove_snapshot 1')
    #job.should_receive(:after_rsync).with(command, '1')
    expect(job).to receive(:after_remove_snapshot).with(command, '1')
    job.run_callback(command)
  end

  it "should prepare the filesystem when it starts running and set its status to running" do
    job = FactoryGirl.build(:backup_job, :status => 'queued')
    #job.should_receive(:prepare_fs)
    expect(job).to receive(:prepare_fs)
    job.run
    job.status.should == 'running'
    job.finished.should == false
  end

  it "prepare_fs should ask if the filesystem exists" do
    job = FactoryGirl.build(:backup_job)
    #job.should_receive(:run_command).with("/sbin/zfs list #{job.fs}", "fs_exists")
    expect(job).to receive(:run_command).with("/sbin/zfs list #{job.fs}", "fs_exists")
    job.prepare_fs
  end

  it "should start the rsyncs if the filesystem exists" do
    job =  FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0)
    #job.should_receive(:start_rsyncs)
    expect(job).to receive(:start_rsyncs)
    job.after_fs_exists(command)
  end

  it "should not start the rsyncs if the server is in removal mode" do
    job =  FactoryGirl.build(:backup_job)
    server = job.server
    server.remove_only = true
    server.save
    command = FactoryGirl.build(:command, :exitstatus => 0)
    #job.should_receive(:cleanup)
    expect(job).to receive(:cleanup)
    job.after_fs_exists(command)
  end

  it "should give out an order to create a filesystem if it does not exist" do
    job =  FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 1)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs create #{job.fs}", "create_fs")
    job.after_fs_exists(command)
  end

  it "should check again after filesystem creation" do
    job =  FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0)
    expect(job).to receive(:run_command).with("/sbin/zfs list #{job.fs}", "fs_exists_confirm")
    job.after_create_fs(command)
  end

  it "should fail when the filesystem could not be created" do
    job =  FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 1)
    job.after_create_fs(command)
    job.status.should == 'Unable to create filesystem'
    job.finished.should == true
  end

  it "should fail if the filesystem confimation fails" do
    job =  FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 1)
    job.after_fs_exists_confirm(command)
    job.status.should == 'Unable to create filesystem'
    job.finished.should == true
  end

  it "should start the rsyncs when the confirmation is positive" do
    job =  FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0)
    expect(job).to receive(:start_rsyncs)
    job.after_fs_exists_confirm(command)
  end

  it "should create a rsync command" do
    job =  FactoryGirl.build(:backup_job)
    job.stub(:main_rsync).and_return('stub_for_rsync')
    expect(job).to receive(:run_command).with('stub_for_rsync', "main_rsync")
    job.start_rsyncs
  end

  it "should run split rsyncs after the rsync and update its status" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0)
    now = Time.new
    Time.stub(:new).and_return now
    expect(job).to receive(:run_split_rsyncs)
    job.after_main_rsync(command)
    job.status.should == 'OK'
  end

  it "should run the first rsync in the array" do
    job = FactoryGirl.build(:backup_job)
    job.stub(:get_rsyncs).and_return('0!RSYNC!1!RSYNC!2')
    expect(job).to receive(:run_command).with('0', "split_rsync")
    job.run_split_rsyncs
    job.rsyncs.size.should == 2
  end

  it "should delete the first rsync in the array if its not the first call" do
    job = FactoryGirl.build(:backup_job)
    job.stub(:get_rsyncs).and_return('rsync0!RSYNC!rsync1!RSYNC!rsync2')
    expect(job).to receive(:run_command).with('rsync0', "split_rsync")
    job.run_split_rsyncs
    job.rsyncs.size.should == 2
    expect(job).to receive(:run_command).with('rsync1', "split_rsync")
    job.run_split_rsyncs
    job.rsyncs.size.should == 1
  end

  it "should create the snapshot after the last rsync command" do
    job = FactoryGirl.build(:backup_job)
    job.stub(:get_rsyncs).and_return('0!RSYNC!1')
    job.run_split_rsyncs
    job.rsyncs.size.should == 1
    job.run_split_rsyncs
    job.rsyncs.size.should == 0
    expect(job).to receive(:do_snapshot)
    job.run_split_rsyncs
    job.rsyncs.size.should == 0
  end

  it "should not snapshot when the main rsync failed" do
    job = FactoryGirl.build(:backup_job, :status => 'FAIL')
    job.stub(:get_rsyncs).and_return('0!RSYNC!1')
    job.run_split_rsyncs
    job.rsyncs.size.should == 1
    job.run_split_rsyncs
    job.rsyncs.size.should == 0
    expect(job).not_to receive(:do_snapshot)
    job.run_split_rsyncs
    job.finished.should == true
  end

  it "should cleanup after the snapshot" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0)
    expect(job).to receive(:cleanup)
    job.after_snapshot(command)
  end

  it "should update the disk usage and ask for the free space for the backup server" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0, :output => '11')
    expect(job).to receive(:run_command).with("/sbin/zfs get -Hp available,used backup | awk '{print $3}'", "backupserver_diskspace")
    job.after_diskusage(command)
    job.server.usage.should == 11
  end

  it "should update the snapshots for a server and ask the disk_usage for the server" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0, :output => '1234
5678
90')
    expect(job).to receive(:run_command).with("/sbin/zfs get -Hp used backup/#{job.server.hostname} | /usr/gnu/bin/awk '{print $3}'", "diskusage")
    job.after_get_snapshots(command)
    job.server.snapshots.should == '1234,5678,90'
  end

  it "should remove old backup jobs for a server" do
    server = FactoryGirl.create(:server)
    job = FactoryGirl.create(:backup_job, :server => server)
    job.server.should_receive(:cleanup_old_jobs)
    expect(job).to receive(:remove_old_snapshots)
    job.cleanup
  end

  it "should remove old snapshots for a server" do
    server = FactoryGirl.create(:server, :hostname => 'server1', :keep_snapshots => 5, :snapshots => 'snap1,snap2,snap3,snap4,snap5,snap6')
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/server1@snap1", "remove_snapshot snap1")
    job.remove_old_snapshots
    server.snapshots.should == 'snap2,snap3,snap4,snap5,snap6'
  end

  it "should get all snapshots for a server when cleanup is done" do
    server = FactoryGirl.create(:server, :hostname => 'serverx1', :keep_snapshots => 6, :snapshots => 'snap1,snap2,snap3,snap4,snap5,snap6')
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/sbin/zfs list -H -r -o name -t snapshot backup/serverx1 | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
    job.remove_old_snapshots
    server.snapshots.should == 'snap1,snap2,snap3,snap4,snap5,snap6'
  end

  it "should remove the oldest snapshot when it is completely out of range" do
    snaps = '1427033911,1427120348,1427206761,1427293237,1427379649,1427466019,1427552512,1427638945,1427725363,1427811865,1427898253,1427984738,1428071128,1428157598,1428244049,1428330505,1428416971,1428503403,1428589808,1428703873,1428810529,1428951991'
    snaps2 = snaps.gsub(/^\d+,/, '')
    server = FactoryGirl.create(:server, :hostname => 'server1', :keep_snapshots => 5,
      :retention_days => 4, :retention_weeks => 2, :retention_months => 0, :snapshots => snaps)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/server1@1427033911", "remove_snapshot 1427033911")
    job.remove_old_snapshots
    server.snapshots.should == snaps2
  end

  it "should remove the snapshot with the shortest interval when all snapshots are in range" do
    snaps = '1427033911,1427120348,1427206761,1427293237,1427379649,1427466019,1427552512,1427638945,1427725363,1427811865,1427898253,1427984738,1428071128,1428157598,1428244049,1428330505,1428416971,1428503403,1428589808,1428703873,1428810529,1428951991'
    snaps2 = snaps.gsub(/,1427379649,/, ',')
    server = FactoryGirl.create(:server, :hostname => 'server1', :keep_snapshots => 5,
      :retention_days => 7, :retention_weeks => 8, :retention_months => 0, :snapshots => snaps)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/server1@1427379649", "remove_snapshot 1427379649")
    job.remove_old_snapshots
    server.snapshots.should == snaps2
  end

  it "should run split_rsyncs after one rsync is finished" do
    job = FactoryGirl.build(:backup_job)
    expect(job).to receive(:run_split_rsyncs)
    job.after_split_rsync(true)
  end

  it "should update the diskspace for the backup server" do
    job = FactoryGirl.build(:backup_job)
    command = FactoryGirl.build(:command, :exitstatus => 0, :output => '2133674676224')
    job.after_backupserver_diskspace(command)
    job.backup_server.disk_free.should == 2133674676224
    job.finished.should == true
  end

  it "should remove the filesystem when there are no snapshots left and server is in removal_only" do
    server = FactoryGirl.create(:server, :hostname => 'serverx2', :snapshots => '', :remove_only => true)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/serverx2", "remove_fs")
    job.remove_old_snapshots
  end

  it "should decrease the number of snapshots to keep if all old snapshots are deleted" do
    server = FactoryGirl.create(:server, :hostname => 'serverx3', :snapshots => 'snap1,snap2', :keep_snapshots => 2, :remove_only => true)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/sbin/zfs list -H -r -o name -t snapshot backup/serverx3 | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
    job.remove_old_snapshots
    server.keep_snapshots.should == 1
  end

  it "should only remove one snapshot at a time when the server is in remove_only" do
    server = FactoryGirl.create(:server, :hostname => 'serverx4', :snapshots => 'snap1,snap2', :keep_snapshots => 1, :remove_only => true)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/serverx4@snap1", "remove_snapshot snap1")
    job.remove_old_snapshots
    server.snapshots.should == 'snap2'
  end

  it "should just take stock of the last snapshot when the server is in remove_only and keep_snapshots is still one (first phase)" do
    server = FactoryGirl.create(:server, :hostname => 'serverx4', :snapshots => 'snap2', :keep_snapshots => 1, :remove_only => true)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/sbin/zfs list -H -r -o name -t snapshot backup/serverx4 | /usr/gnu/bin/sed -e 's/.*@//'", "get_snapshots")
    job.remove_old_snapshots
    server.snapshots.should == 'snap2'
  end

  it "should kill off the last snapshot when the server is in remove_only and keep_snapshots is zero (second phase)" do
    server = FactoryGirl.create(:server, :hostname => 'serverx4', :snapshots => 'snap2', :keep_snapshots => 0, :remove_only => true)
    job = FactoryGirl.create(:backup_job, :server => server)
    expect(job).to receive(:run_command).with("/bin/pfexec /sbin/zfs destroy backup/serverx4@snap2", "remove_snapshot snap2")
    server.snapshots.should == 'snap2'
    job.remove_old_snapshots
    server.snapshots.should == ''
  end

  it "should remove the server is the filesystem is removed" do
    server = FactoryGirl.create(:server, :snapshots => '', :remove_only => true)
    job = FactoryGirl.create(:backup_job, :server => server)
    server.should_receive(:destroy)
    job.after_remove_fs(true)
    job.finished?.should == true
  end
end
