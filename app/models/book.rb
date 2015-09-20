class Book < ActiveRecord::Base
  attr_accessible :author, :filename, :location, :title
  mount_uploader :location, EpubUploader

  belongs_to :user
  has_many :contents, dependent: :destroy

  # validates :author, :filename, :location, :title, :user_id, presence: true
end
