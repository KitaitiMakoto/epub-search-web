require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.books = [books(:one), books(:two)]
  end

  test 'must not create without username' do
    assert !User.new(password: 'password').save
  end

  test 'must not create without password' do
    assert !User.new(username: 'username').save
  end

  test 'must not access password digest' do
    assert_raise {@user.password_digest}
  end

  test 'must have many books' do
    assert_instance_of Array, @user.books
    assert_instance_of Book, @user.books.first
  end
end
