# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_component}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Genki Takiuchi"]
  s.date = %q{2009-01-26}
  s.description = %q{Merb plugin that provides composition of controllers.}
  s.email = %q{genki@s21g.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/merb_component", "lib/merb_component/controller_ext.rb", "lib/merb_component/merbtasks.rb", "lib/merb_component/resource_ext.rb", "lib/merb_component/router_ext.rb", "lib/merb_component.rb", "spec/admin_spec.rb", "spec/fixture", "spec/fixture/app", "spec/fixture/app/controllers", "spec/fixture/app/controllers/admin.rb", "spec/fixture/app/controllers/application.rb", "spec/fixture/app/controllers/comments.rb", "spec/fixture/app/controllers/posts.rb", "spec/fixture/app/models", "spec/fixture/app/models/comment.rb", "spec/fixture/app/models/post.rb", "spec/fixture/app/views", "spec/fixture/app/views/admin", "spec/fixture/app/views/admin/show.html.erb", "spec/fixture/app/views/comments", "spec/fixture/app/views/comments/edit.html.erb", "spec/fixture/app/views/comments/index.html.erb", "spec/fixture/app/views/comments/new.html.erb", "spec/fixture/app/views/layout", "spec/fixture/app/views/layout/application.html.erb", "spec/fixture/app/views/posts", "spec/fixture/app/views/posts/index.html.erb", "spec/fixture/app/views/posts/show.html.erb", "spec/fixture/config", "spec/fixture/config/router.rb", "spec/merb_component_spec.rb", "spec/posts_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://blog.s21g.com/genki}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Merb plugin that provides composition of controllers.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb>, [">= 1.0.7.1"])
    else
      s.add_dependency(%q<merb>, [">= 1.0.7.1"])
    end
  else
    s.add_dependency(%q<merb>, [">= 1.0.7.1"])
  end
end
