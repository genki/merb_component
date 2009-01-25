class Merb::Controller
  METHOD_TO_ACTION = {
    :get => :edit,
    :post => :create,
    :put => :update,
    :delete => :destroy
  }.freeze

  class << self
  private
    def aggregates(aggregation, options = {})
      if aggregation.is_a?(Symbol)
        aggregation = {:show => aggregation}
      end
      aggregation.each do |action, arg|
        define_method(arg){} unless method_defined?(arg)
        model = Object.full_const_get(arg.to_s.singular.camel_case)
        key = "#{controller_name.singular}_id"
        var = "@#{arg.to_s.singular}"

        add_filter(_before_filters, proc{|c|
          # setup request
          id = params.delete(key)
          req = request.dup
          req.reset_params!
          req.instance_variable_set(:@params, params.merge(
            :controller => arg, :action => METHOD_TO_ACTION[req.method]))

          # call action of subsidiary controller with scope
          cc = Object.full_const_get(params[:action].camel_case).new(req)
          scope = Mash.new
          scope[key] = id if id
          model.send :with_scope, scope do
            begin
              layout = cc.class.default_layout
              cc.class.layout(options[:layout])
              response = Aggregator.new(c, cc.class) do
                cc._abstract_dispatch(req.params[:action])
              end.result
            ensure
              cc.class.layout(layout)
            end
            c.throw_content("from_#{arg}".intern, response)
            result = cc.instance_variable_get(var)
            c.instance_variable_set(var, result)
          end

          # prepare for performing actoin of principal controller
          params[:id] = id if id
          params[:action] = c.action_name = action
        }, :only => arg)
      end
    end
  end

  class Aggregator
    attr_reader :controller, :object, :result

    def initialize(context, controller, &block)
      @context = context
      @controller = controller
      @agg_name = @context.controller_name.singular.intern
      model_class = Object.full_const_get(controller.name.singular)
      @object = @context.instance_variable_get("@#{@agg_name}")
      @scope = {}

      if @object
        relationship = model_class.relationships[@agg_name]
        key_names = relationship.child_key.map{|i| i.name}
        @scope = Hash[key_names.zip(@object.key)] if @object
      end

      @result = begin
        Thread.critical = true
        aggregators = Thread::current[:aggregators] ||= {}
        (aggregators[controller] ||= []).push(self)
        if model_class.respond_to?(:with_scope)
          model_class.send(:with_scope, @scope, &block)
        else
          block.call
        end
      ensure
        aggregators[controller].pop
        Thread.critical = false
      end
    end

    def resource(*args)
      if (key = @object || @agg_name) && !(@controller <=> @context.class)
        @context.send :resource, key, *args
      else
        @context.send :resource, *args
      end
    end
  end

  def _abstract_dispatch(*args)
    _dispatch = Merb::AbstractController.instance_method(:_dispatch)
    _dispatch.bind(self).call(*args)
  end

  def aggregator
    aggregators = Thread::current[:aggregators] ||= {}
    (aggregators[self.class] ||= []).last
  end

private
  def component(controller, action, params = {})
    if controller.is_a?(Symbol)
      controller = Object.full_const_get(controller.to_s.camel_case)
    end
    req = request.dup
    req.reset_params!
    req.instance_variable_set :@params, params

    Aggregator.new(self, controller) do
      controller.new(req)._dispatch(action).render :layout => false
    end.result
  end

  def resource(first, *args)
    model = case first
    when Symbol, String
      Object.full_const_get(first.to_s.singular.camel_case)
    else first.class
    end
    return super if !aggregator
    aggregator.resource(first, *args)
  end
end
