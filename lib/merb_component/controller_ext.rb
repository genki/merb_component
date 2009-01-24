class Merb::Controller
  REST_TABLE = {
    :post => :create,
    :put => :update,
    :delete => :destroy
  }

  class << self
  private
    def aggregates(*args)
      @aggregations ||= Mash.new
      options = extract_options_from_args!(args) || {}
      args.each do |arg|
        define_method(arg){} unless method_defined?(arg)
        model = Object.full_const_get(arg.to_s.singular.camel_case)
        key = "#{controller_name.singular}_id"

        add_filter(_before_filters, proc{|c|
          # setup request
          id = params.delete(key)
          req = request.dup
          req.reset_params!
          req.instance_variable_set(:@params, params.merge(
            :controller => arg, :action => REST_TABLE[req.method]))

          # call action of subsidiary controller with scope
          cc = Object.full_const_get(params[:action].camel_case).new(req)
          model.send :with_scope, key => id do
            result = cc._abstract_dispatch(req.params[:action])
            c.instance_variable_set("@#{arg.to_s.singular}", result)
          end

          # prepare for performing actoin of principal controller
          params[:id] = id
          params[:action] = c.action_name = :show
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
    req = request.dup
    req.reset_params!
    req.instance_variable_set :@params, params
    controller.new(req)._abstract_dispatch(action)
  end

  def resource(first, *args)
    model = case first
    when Symbol, String
      Object.full_const_get(first.to_s.singular.camel_case)
    else first.class
    end
    return super unless model.relation
    super(model.relation, first, *args)
  end
end
