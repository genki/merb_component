require File.dirname(__FILE__) + '/spec_helper'

describe "merb_component" do
  it "should extend controller" do
    Posts.private_instance_methods.should be_include("component")
  end

  it "should extend model" do
    Post.public_methods.should be_include("related_with")
  end
end
