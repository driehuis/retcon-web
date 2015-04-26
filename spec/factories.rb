FactoryGirl.define do
  factory :server do
    sequence(:hostname) {|n| "server#{n}.example.com" }
    enabled true
    ssh_port 22
    interval_hours 24
    keep_snapshots 30
    association :backup_server
    path '/'
  end
end

FactoryGirl.define do
  factory :backup_server do
    sequence(:hostname) {|n| "backup#{n}.example.com" }
    zpool "backup"
    max_backups 10
    association :user
  end
end

FactoryGirl.define do
  factory :profile do
    sequence(:name) {|n| "profile#{n}" }
  end
end

FactoryGirl.define do
  factory :quirk do
    sequence(:name) {|n| "quirk#{n}" }
    description "Quirk"
  end
end

FactoryGirl.define do
  factory :user do
    sequence(:username) {|n| "user#{n}" }
    password 'testing'
    password_confirmation 'testing'
  end
end

FactoryGirl.define do
  factory :exclude do
    sequence(:path) {|n| "/exclude/#{n}" }
    association :profile
  end
end

FactoryGirl.define do
  factory :include do
    sequence(:path) {|n| "/include/#{n}" }
    association :profile
  end
end

FactoryGirl.define do
  factory :split do
    path "/home/"
    depth 1
    association :profile
  end
end

FactoryGirl.define do
  factory :backup_job do
    association :backup_server
    association :server
    status 'running'
  end
end

FactoryGirl.define do
  factory :command do
    association :backup_job
    command 'ls'
    label 'rsync 1'
    exitstatus 0
    output 'w00t'
  end
end
