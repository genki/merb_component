class Admin < Application
  aggregates :comments

  def index
    @comments = Comment.all
    render
  end
end
