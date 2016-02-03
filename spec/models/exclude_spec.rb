require 'spec_helper'

describe Exclude do

  it "should create a new instance given valid attributes" do
    e = FactoryGirl.build :exclude
    e.valid?.should be true
  end

  it "should not be valid when no path is given" do
    e = FactoryGirl.build :exclude, :path => nil
    e.valid?.should be false
  end

  it "should not be valid when no profile is given" do
    e = FactoryGirl.build :exclude, :profile_id => nil
    e.valid?.should be false
  end

  it "should respond to to_s" do
    e = FactoryGirl.build :exclude, :path => '/'
    e.to_s.should == '/'
  end
end
