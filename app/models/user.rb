class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :username, :password
  attr_protected :password_digest

  has_many :books, dependent: :destroy

  validates :username, presence: true
  validates :password, presence: true

  def authenticate(uncrypted_password)
    BCrypt::Password.new(password_digest) == uncrypted_password
  end

  before_save do
    self.password_digest = BCrypt::Password.create(password)
  end
end
