class Posts < Application
  aggregates :comments

  def index
    @posts = Post.all
    display @posts
  end

  def show(id)
    @post = Post.get(id)
    display @post
  end
end
