class User < ActiveRecord::Base
  attr_accessible :password_digest, :username

  has_many :books, dependent: :delete
end
