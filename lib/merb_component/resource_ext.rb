module DataMapper::Resource
  module ClassMethods
    def build(attrs = {})
      all.build(attrs)
    end
  end
end
