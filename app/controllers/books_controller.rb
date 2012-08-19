class BooksController < ApplicationController
  # GET /books
  # GET /books.json
  def index
    @books = Book.where(:user_id => current_user.id)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @books }
    end
  end

  # GET /books/1
  # GET /books/1.json
  def show
    @book = Book.find_by_id_and_user_id!(params[:id], current_user.id)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @book }
      format.epub { send_file @book.location.url, filename: @book.filename, dispositioin: 'attachment', type: 'application/epub+zip' }
    end
  end

  # GET /books/new
  # GET /books/new.json
  def new
    @book = Book.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @book }
    end
  end

  # POST /books
  # POST /books.json
  def create
    file = params[:book].delete(:file)
    book_info = EPUB::Parser.parse(file.tempfile).package.metadata
    @book = Book.new(params[:book])
    @book.title = book_info.title
    @book.author = book_info.creators.join
    @book.filename = File.basename(file.original_filename)
    @book.location = file

    respond_to do |format|
      if current_user.books << @book
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render json: @book, status: :created, location: @book }
      else
        format.html { render action: "new" }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    # TODO: add key for [id, user_id] to books table
    @book = Book.find_by_id_and_user_id!(params[:id], current_user.id)
    @book.destroy

    respond_to do |format|
      format.html { redirect_to books_url }
      format.json { head :no_content }
    end
  end
end
