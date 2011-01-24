class Split < ActiveRecord::Base
  belongs_to :profile
  validates_presence_of :path, :depth
  
  def to_s
    path
  end
end
