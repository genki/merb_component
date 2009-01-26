require File.dirname(__FILE__) + '/spec_helper'

describe Admin do
  before do
    @req = Merb::Request.new(
      Merb::Const::REQUEST_PATH => "/admin",
      Merb::Const::REQUEST_METHOD => "GET",
      Merb::Const::QUERY_STRING => "")
    @c = Admin.new(@req)
  end

  it "should be a controller" do
    @c.should be_kind_of(Merb::Controller)
  end
end

describe "Admin controller" do
  before :all do
    @post = Post.create
    @comment = @post.comments.create(:body => "test")
  end

  it "should be tested on at least one post and comment" do
    Post.count.should > 0
    Comment.count.should > 0
  end

  it "should show index html" do
    res = request(resource(:admin))
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li")
    res.should_not have_xpath("//form")
    res.should have_xpath("//a[@href='/admin/comments?page=1']")
  end

  it "should show index html for pagination params" do
    res = request("/admin/comments?page=2")
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul")
    res.should_not have_xpath("//form")
    res.should have_xpath("//a[@href='/admin/comments?page=3']")
  end

  it "should show html after update a comment" do
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(:admin, comment),
      :method => 'PUT', :params => {:comment => {:body => "bar"}})
    res.should redirect_to("/admin")

    res = request(res.headers["Location"])
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should_not have_xpath("//form")
  end

  it "should show html after failed to update a comment" do
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(:admin, comment),
      :method => 'PUT', :params => {:comment => {:body => ""}})
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//ul/li[1]")
    res.should have_xpath("//form[@action='/admin/comments/#{comment.id}']")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//input[@value='put']")
    res.should have_tag("div.error")
    res.should have_tag("input.error[@name='comment[body]']")
  end

  it "should show html after delete a comment" do
    count = @post.comments.count
    comment = @post.comments.last
    comment.should be_kind_of(Comment)
    res = request(resource(:admin, comment), :method => 'DELETE')
    res.should redirect_to("/admin")
    
    res = request(res.headers["Location"])
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should_not have_xpath("//form")
    @post.comments.count.should == count - 1
  end

  it "should show html after show a comment" do
    comment = @post.comments.create(:body => "hello")
    comment.should_not be_new_record
    res = request(resource(:admin, comment), :method => 'GET')
    res.should be_successful
    res.should have_xpath("//h1")
    res.should have_xpath("//h2")
    res.should have_xpath("//form[@action='/admin/comments/#{comment.id}']")
    res.should have_xpath("//form[@method='post']")
    res.should have_xpath("//input[@value='put']")
    res.should_not have_xpath("//body/meta")
  end
end
