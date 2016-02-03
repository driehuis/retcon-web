class Setting < ActiveRecord::Base
  validates_presence_of :name, :value

  def self.[](thing=nil)
    find_by_name(thing).last.value
  end

end
