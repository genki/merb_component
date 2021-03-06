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
    @comment = @post.comments.create(:body => "test")
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
    res.should_not have_xpath("//input[@value='put']")
    res.should have_xpath("//input[@value='new']")
    res.should have_xpath("//a[@href='/posts/#{@post.id}/comments?page=1']")
    res.should contain("test_content")
  end

  it "should show html for pagination params" do
    res = request("/posts/#{@post.id}/comments?page=2")
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//form[@action='/posts/#{@post.id}/comments']")
    res.should_not have_xpath("//input[@value='put']")
    res.should have_xpath("//input[@value='new']")
    res.should have_xpath("//a[@href='/posts/#{@post.id}/comments?page=3']")
    end

  it "should show html after post a comment" do
    count = @post.comments.count
    res = request(resource(@post, :comments),
      :method => 'POST', :params => {:comment => {:body => "foo"}})
    res.should redirect_to("/posts/#{@post.id}")

    res = request(res.headers["Location"])
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//ul/li[2]")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//form[@action='/posts/#{@post.id}/comments']")
    res.should_not have_xpath("//input[@value='put']")
    res.should contain("foo")
    Comment.all(:post_id => @post.id).count.should == count + 1
  end

  it "should show html after failed to post a comment" do
    count = Comment.all(:post_id => @post.id).count
    res = request(resource(@post, :comments),
      :method => 'POST', :params => {:comment => {:body => ""}})
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//ul/li[2]")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//form[@action='/posts/#{@post.id}/comments']")
    res.should_not have_xpath("//input[@value='put']")
    res.should have_tag("div.error")
    res.should have_tag("input.error[@name='comment[body]']")
    Comment.all(:post_id => @post.id).count.should == count
  end

  it "should show html after update a comment" do
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(@post, comment),
      :method => 'PUT', :params => {:comment => {:body => "bar"}})
    res.should redirect_to("/posts/#{@post.id}")

    res = request(res.headers["Location"])
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//ul/li[2]")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//form[@action='/posts/#{@post.id}/comments']")
    res.should_not have_xpath("//input[@value='put']")
    res.should contain("bar")
  end

  it "should show html after failed to update a comment" do
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(@post, comment),
      :method => 'PUT', :params => {:comment => {:body => ""}})
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//ul/li[2]")
    res.should have_xpath("//form[@method='post']")
    url = "/posts/#{@post.id}/comments/#{comment.id}"
    res.should have_xpath("//form[@action='#{url}']")
    res.should have_xpath("//input[@value='put']")
    res.should have_tag("div.error")
    res.should have_tag("input.error[@name='comment[body]']")
  end

  it "should show html after delete a comment" do
    count = @post.comments.count
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(@post, comment), :method => 'DELETE')
    res.should redirect_to("/posts/#{@post.id}")
    
    res = request(res.headers["Location"])
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//form[@action='/posts/#{@post.id}/comments']")
    res.should have_xpath("//form[@method='post']")
    res.should_not have_xpath("//input[@value='put']")
    @post.comments.count.should == count - 1
  end

  it "should show html after show a comment" do
    comment = @post.comments.create(:body => "test")
    comment.should_not be_new_record
    res = request(resource(@post, comment), :method => 'GET')
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    url = "/posts/#{@post.id}/comments/#{comment.id}"
    res.should have_xpath("//form[@action='#{url}']")
    res.should have_xpath("//input[@value='put']")
    res.should_not have_xpath("//body/meta")
    res.should have_xpath("//input[@value='edit']")

    pending "should check pagination"
  end

  it "should provide atom feed for comments" do
    comment = @post.comments.create(:body => "test")
    comment.should_not be_new_record
    res = request(resource(@post, :comments, :format => :atom))
    res.should be_successful
    res.should have_xpath("//feed/title")
    url = "http://example.org/posts/#{@post.id}/comments"
    res.should have_xpath("//feed/link[@href='#{url}']")
    res.should have_xpath("//entry/title")
    url = "http://example.org/posts/#{@post.id}/comments/#{comment.id}"
    res.should have_xpath("//entry/link[@href='#{url}']")
  end
end
