require File.dirname(__FILE__) + '/spec_helper'

describe "merb_component" do
  it "should extend controller" do
    Posts.private_instance_methods.should be_include("component")
  end

  it "should extend model" do
    Post.public_methods.should be_include("related_with")
  end

  it "should accept controller class as the first param of compoent" do
    req = Merb::Request.new({})
    result = Posts.new(req).send(:component, Comments, :index)
    result.should be_kind_of(String)
  end

  it "should accept symbol as the first param of compoent" do
    req = Merb::Request.new({})
    result = Posts.new(req).send(:component, :comments, :index)
    result.should be_kind_of(String)
  end
end
