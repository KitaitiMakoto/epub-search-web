class Book < ActiveRecord::Base
  attr_accessible :author, :epub, :title

  belongs_to :user
  has_many :contents, dependent: :destroy

  mount_uploader :epub, EpubUploader
end
