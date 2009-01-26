module DataMapper::Resource
  module ClassMethods
    # set scope
    def new(attrs = {})
      flag = attrs.delete(:without_scope)
      return super(attrs) if flag
      all.build(attrs.merge(:without_scope => true))
    end
  end
end
