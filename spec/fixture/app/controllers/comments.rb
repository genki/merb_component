class Comments < Application
  def index
    @comments = Comment.all
    display @comments
  end

  def new
    @comment = Comment.build
    display @comment
  end
end
