class Merb::Controller
  METHOD_TO_ACTION = {
    :post => :create,
    :put => :update,
    :delete => :destroy
  }.freeze

  class << self
  private
    def is_component(resource = nil)
      resource = controller_name.singular if resource.nil?
      r = resource.to_s
      m = r.camel_case
      iv = proc{|i| "(@#{r} = #{m}.#{i})"}
      ivs = proc{|i| "(@#{r.pluralize} = #{m}.#{i})"}
      class_eval <<-"RUBY"
        def index; display #{ivs["all"]} end
        def show(id) display #{iv["get(id)"]} end
        def new; display #{iv["new"]} end
        def edit(id) display #{iv["get(id)"]} end
        def create(#{r}) #{iv["create(#{r})"]} end
        def update(id,#{r}) #{iv["get(id)"]}.update_attributes(#{r}) end
        def destroy(id) #{iv["get(id)"]}.destroy end
      RUBY
    end

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
              throw(:halt, proc{
                target = controller_name.singular.intern
                target = object.send(target) if object.respond_to?(target)
                redirect resource(target)
              }) if object.errors.empty?
              c.instance_variable_set(var, object)
            end
          elsif params[:id]
            # GET with component id
            object = model.get(params[:id])
            c.instance_variable_set(var, object)
          elsif params[:format]
            @component_format = params.delete(:format)
            #c._abstract_dispatch(action)
          end
          c.instance_variable_set("#{var}_component", object)

          # prepare for performing actoin of principal controller
          c.params[:id] = id if id
          c.params[:action] = c.action_name = agg_action.to_s
        }, :only => arg)

        add_filter(_after_filters, proc{|c|
          # setup request
          request.reset_params!
          request.instance_variable_set(:@params, params.merge(
            :controller => arg, :action => :index,
            :format => @component_format))

          # call index action of subsidiary controller with scope
          cc = Object.full_const_get(arg.to_s.camel_case).new(request)
          @body = Aggregator.new(c, cc.class) do
            cc._abstract_dispatch(:index)
          end.result
        }, :only => agg_action, :if => proc{@component_format})
      end
    end
  end

  class Aggregator
    attr_reader :controller, :object, :result, :context

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

  def url_with_scope(*args)
    result = url_without_scope(*args)
    if (agg = aggregator) && (key = agg.key)
      resource_without_scope(key) + result
    else
      result
    end
  end
  alias_method :url_without_scope, :url
  alias_method :url, :url_with_scope

private
  def component(controller, action, params = {})
    params = self.params.merge(
      :controller => controller, :action => action
    ).merge(params)
    var = "@#{controller.to_s.singular}"
    object = instance_variable_get("#{var}_component")
    controller = Object.full_const_get(controller.to_s.camel_case)
    req = request.dup
    req.reset_params!
    req.instance_variable_set :@params, params

    Aggregator.new(self, controller) do
      controller.new(req)._dispatch(action).instance_eval do
        if object
          original = instance_variable_get(var)
          object.attributes = original.attributes if original
          instance_variable_set(var, object)
        end
        render :layout => false
      end
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

  def resource_with_scope(first, *args)
    agg = aggregator
    return resource_without_scope(first, *args) unless agg

    controller = case first
    when Symbol, String
      Object.full_const_get(first.to_s.camel_case)
    else
      Object.full_const_get(first.class.to_s.pluralize.camel_case)
    end

    if controller <=> agg.controller && agg.key
      resource_without_scope(agg.key, first, *args)
    else
      resource_without_scope(first, *args)
    end
  end
  alias_method :resource_without_scope, :resource
  alias_method :resource, :resource_with_scope
end
