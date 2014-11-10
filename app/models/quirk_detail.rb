class QuirkDetail < ActiveRecord::Base
  belongs_to :server
  belongs_to :quirk
end
