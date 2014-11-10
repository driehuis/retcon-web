class Quirk < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :description

  has_many :quirk_details, :dependent => :destroy
  has_many :servers, :through => :quirk_details
end
