require File.dirname(__FILE__) + '/spec_helper'

describe "merb_component" do
  it "should extend controller" do
    Posts.private_instance_methods.should be_include("component")
    Posts.private_instance_methods.should be_include("form_for_component")
    Posts.instance_methods.should be_include("aggregator")
  end

  it "should not extend model" do
    Post.public_methods.should_not be_include("related_with")
  end

  it "should accept symbol as the first param of compoent" do
    req = Merb::Request.new({})
    c = Posts.new(req)
    proc do
      c.send(:component, :comments, :index)
    end.should raise_error(Merb::Router::GenerationError)
    c.instance_variable_set(:@post, Post.create)
    result = c.send(:component, :comments, :index)
    result.should be_kind_of(String)
  end
end
