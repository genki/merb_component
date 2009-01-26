module DataMapper::Resource
  module ClassMethods
    # set scope
    def new(attrs = {})
      collection = all
      collection.repository.scope do
        super(collection.default_attributes.merge(attrs))
      end
    end
  end
end
