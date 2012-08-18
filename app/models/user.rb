class User < ActiveRecord::Base
  attr_accessible :username, :password
  attr_accessor :password

  has_many :books, dependent: :destroy

  def authenticate(uncrypted_password)
    BCrypt::Password.new(password_digest) == uncrypted_password
  end

  before_save do
    self.password_digest = BCrypt::Password.create(password)
  end
end
