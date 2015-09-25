class QuirkDetail < ActiveRecord::Base
  validates_presence_of :comment
  belongs_to :server
  belongs_to :quirk
end
