class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user

  private

  def current_user
    if session[:user_id]
      @current_user ||= User.find_by_id(session[:user_id])
    end
  end
  helper_method :current_user

  def authenticate_user
    redirect_to [:new, :session] unless current_user
  end
end
