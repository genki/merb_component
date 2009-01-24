class Merb::Controller
  class << self
  private
    def aggregates(*args)
      @aggregations ||= Mash.new
      options = extract_options_from_args!(args) || {}
      args.each do |arg|
        @aggregations[arg] = Object.const_get arg.to_s.camel_case
      end
    end
  end

private
  def component(controller, action, params = {})
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
    return super unless model.relation
    super(model.relation, first, *args)
  end
end
