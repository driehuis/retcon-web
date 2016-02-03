require 'spec_helper'

describe Profile do
  before do
    Profile.destroy_all
  end

  it "should create a new instance given valid attributes" do
    p = FactoryGirl.build(:profile)
    p.valid?.should be true
  end

  it "should not allow a missing name" do
    p = FactoryGirl.build(:profile, :name => nil)
    p.valid?.should be false
  end

  it "should be possible to create an exclusive profile" do
    p = FactoryGirl.build(:profile, :exclusive => true)
    p.valid?.should be true
  end

  it "should have a class method to fetch all public profiles" do
    p1 = FactoryGirl.create(:profile, :exclusive => true)
    p2 = FactoryGirl.create(:profile)
    results = Profile.public
    results.count.should == 1
    results[0].exclusive.should == false
  end

  it "should only allow to attach an exclusive profile to one server" do
    s1 = FactoryGirl.create(:server)
    s2 = FactoryGirl.create(:server)
    p = FactoryGirl.create(:profile, :exclusive => true)
    p.servers << s1
    p.valid?.should == true
    p.servers << s2
    p.valid?.should == false
  end
end
