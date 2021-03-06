class SessionsController < ApplicationController
  skip_before_filter :authenticate_user

  def create
    user = User.find_by_username(params[:username])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to :books
    else
      render :new
    end
  end

  def destroy
    session.delete :user_id
    redirect_to [:new, :session]
  end
end
