require 'spec_helper'

describe Quirk do
  before do
    Quirk.destroy_all
  end

  it "should create a new instance given valid attributes" do
    p = Factory.build(:quirk)
    p.valid?.should be true
  end

  it "should not allow a missing name" do
    p = Factory.build(:quirk, :name => nil)
    p.valid?.should be false
  end

  it "should not allow a missing description" do
    p = Factory.build(:quirk, :description => nil)
    p.valid?.should be false
  end
end
