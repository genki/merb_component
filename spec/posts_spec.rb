require File.dirname(__FILE__) + '/spec_helper'

describe Posts do
  before do
    @req = Merb::Request.new(
      Merb::Const::REQUEST_PATH => "/posts",
      Merb::Const::REQUEST_METHOD => "GET",
      Merb::Const::QUERY_STRING => "")
    @c = Posts.new(@req)
  end

  it "should be a controller" do
    @c.should be_kind_of(Merb::Controller)
  end
end

describe "Posts controller" do
  before :all do
    @post = Post.create
    @comment = @post.comments.create
  end

  it "should be tested on at least one post" do
    Post.count.should > 0
    Comment.count.should > 0
  end

  it "should show html" do
    res = request(resource(@post))
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//form[@action='/posts/#{@post.id}/comments']")
  end
end
