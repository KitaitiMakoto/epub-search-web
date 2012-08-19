class ContentsController < ApplicationController
  # GET /contents
  # GET /contents.json
  def index
    @q = params[:q]
    if @q.blank?
      @contents = []
    else
      @contents = Content.joins(:book).where(books: {user_id: current_user.id})\
        .where(['MATCH (content) AGAINST (?)', @q])\
        .order(:contents => ['MATCH (content) AGAINST (?) DESC', @q])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @contents }
    end
  end
end
