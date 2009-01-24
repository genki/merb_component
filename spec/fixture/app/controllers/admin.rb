class Admin < Application
  aggregates :show => :comments

  def show
    render
  end
end
