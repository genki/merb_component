class Comments < Application
  def index
    @comments = Comment.all
    display @comments
  end

  def new
    @comment = Comment.new
    display @comment
  end

  def edit(id)
    @comment = Comment.get(id)
    display @comment
  end

  def create(comment)
    @comment = Comment.all.create(comment)
  end

  def update(id, comment)
    @comment = Comment.get(id)
    @comment.update_attributes(comment)
  end

  def destroy(id)
    @comment = Comment.get(id)
    @comment.destroy
  end
end
