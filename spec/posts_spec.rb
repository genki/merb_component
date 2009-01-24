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

  it "should show html after post a comment" do
    count = @post.comments.count
    res = request(resource(@post, :comments),
      :method => 'POST', :params => {:comment => {:body => "foo"}})
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//ul/li[2]")
    res.should have_xpath("//form[@method='post']")
    res.should contain("foo")
    Comment.all(:post_id => @post.id).count.should == count + 1
  end

  it "should show html after update a comment" do
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(@post, comment),
      :method => 'PUT', :params => {:comment => {:body => "bar"}})
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//ul/li[2]")
    res.should have_xpath("//form[@method='post']")
    res.should contain("bar")
  end

  it "should show html after update a comment" do
    count = @post.comments.count
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(@post, comment), :method => 'DELETE')
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    @post.comments.count.should == count - 1
  end
end
