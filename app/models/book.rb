class Book < ActiveRecord::Base
  attr_accessible :author, :location, :title

  belongs_to :user
  has_many :contents, dependent: :delete
end
