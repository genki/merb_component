class Comments < Application
  def index
    @comments = Comment.all
    display @comments
  end
end
