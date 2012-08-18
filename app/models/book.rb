class Book < ActiveRecord::Base
  attr_accessible :author, :file, :title
end
