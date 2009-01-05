module DataMapper::Model
  def related_with(model, &block)
    model_class = model.class
    storage_name = model_class.storage_name
    assoc_name = storage_name.singular.intern
    key_names = relationships[assoc_name].child_key.map{|i| i.name}
    push_relation(model)
    with_scope(Hash[key_names.zip(model.key)], &block)
  ensure
    pop_relation
  end

  def relation
    Thread::current[:relation].last
  end

private
  def push_relation(relation)
    Thread::current[:relation] ||= []
    Thread::current[:relation].push relation
  end

  def pop_relation
    Thread::current[:relation].pop
  end
end
