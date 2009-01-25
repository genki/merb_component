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
            cc._abstract_dispatch(req.params[:action])
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

  def _abstract_dispatch(*args)
    _dispatch = Merb::AbstractController.instance_method(:_dispatch)
    _dispatch.bind(self).call(*args)
  end

private
  def component(controller, action, params = {})
    if controller.is_a?(Symbol)
      controller = Object.full_const_get(controller.to_s.camel_case)
    end
    req = request.dup
    req.reset_params!
    req.instance_variable_set :@params, params
    controller.new(req)._dispatch(action).render :layout => false
  end

  def resource(first, *args)
    model = case first
    when Symbol, String
      Object.full_const_get(first.to_s.singular.camel_case)
    else first.class
    end
    return super if !model.relation || model <= model.relation.class
    super(model.relation, first, *args)
  end
end
