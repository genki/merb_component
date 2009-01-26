class Comments < Application
  is_component :comment

  def new
    @comment = Comment.new
    @comment.body = "new"
    display @comment
  end

  def edit(id)
    @comment = Comment.get(id)
    @comment.body = "edit"
    display @comment
  end
end
