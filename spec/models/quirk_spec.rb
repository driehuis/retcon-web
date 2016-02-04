require 'spec_helper'

describe Quirk do
  before do
    Quirk.destroy_all
  end

  it "should create a new instance given valid attributes" do
    p = FactoryGirl.build(:quirk)
    p.valid?.should be true
  end

  it "should not allow a missing name" do
    p = FactoryGirl.build(:quirk, :name => nil)
    p.valid?.should be false
  end

  it "should not allow a missing description" do
    p = FactoryGirl.build(:quirk, :description => nil)
    p.valid?.should be false
  end

  it "should generate a valid QuirkDetail when associated with a Server" do
    q = FactoryGirl.build(:quirk)
    s = FactoryGirl.build(:server)
    qd = QuirkDetail.new(:quirk_id=>q.id, :server_id=>s.id, :comment => '#12345')
    q.valid?.should be true
    s.valid?.should be true
    qd.valid?.should be true
  end

  it "should fail to generate a QuirkDetail with a blank comment" do
    q = FactoryGirl.build(:quirk)
    s = FactoryGirl.build(:server)
    qd = QuirkDetail.new(:quirk_id=>q.id, :server_id=>s.id, :comment => '')
    q.valid?.should be true
    s.valid?.should be true
    qd.valid?.should be false
  end
end
