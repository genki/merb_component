class Merb::Controller
  METHOD_TO_ACTION = {
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
      aggregation.each do |agg_action, arg|
        define_method(arg){} unless method_defined?(arg)
        model = Object.full_const_get(arg.to_s.singular.camel_case)
        key = "#{controller_name.singular}_id"
        var = "@#{arg.to_s.singular}"

        add_filter(_before_filters, proc{|c|
          id = params.delete(key)
          method = request.method
          scope = Mash.new
          scope[key] = id if id
          object = nil
          if action = METHOD_TO_ACTION[method]
            # setup request
            req = request.dup
            req.reset_params!
            req.instance_variable_set(:@params,
              params.merge(:controller => arg, :action => action))

            # call action of subsidiary controller with scope
            cc = Object.full_const_get(params[:action].camel_case).new(req)
            model.send :with_scope, scope do
              begin
                layout = cc.class.default_layout
                cc.class.layout(options[:layout])
                response = cc._abstract_dispatch(action)
              ensure
                cc.class.layout(layout)
              end
              object = cc.instance_variable_get(var)
              c.instance_variable_set(var, object)
              object = model.build
            end
          elsif params[:id]
            # GET with component id
            object = model.get(params[:id])
            c.instance_variable_set(var, object)
          end
          c.instance_variable_set("#{var}_component", object)

          # prepare for performing actoin of principal controller
          c.params[:id] = id if id
          c.params[:action] = c.action_name = agg_action.to_s
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

    def key
      @object || @agg_name
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
    controller = Object.full_const_get(controller.to_s.camel_case)
    req = request.dup
    req.reset_params!
    req.instance_variable_set :@params, params

    Aggregator.new(self, controller) do
      controller.new(req)._dispatch(action).render :layout => false
    end.result
  end

  def form_for_component(controller, params = {}, &block)
    var = "@#{controller.to_s.singular}"
    object = instance_variable_get(var)
    return nil if object.nil?
    object = instance_variable_get("#{var}_component") || object
    if object.new_record?
      component(controller, :new, params)
    else
      component(controller, :edit, {:id => object.id}.merge(params))
    end
  end

  def resource(first, *args)
    return super unless aggregator

    controller = case first
    when Symbol, String
      Object.full_const_get(first.to_s.camel_case)
    else
      Object.full_const_get(first.class.to_s.pluralize.camel_case)
    end

    return super unless controller <=> aggregator.controller
    return super unless key = aggregator.key
    super(key, first, *args)
  end
end
