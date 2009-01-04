class Merb::Controller
private
  def compose(controller, action, params = {})
    req = request.dup
    req.reset_params!
    req.instance_variable_set :@params, params
    controller.new(req)._dispatch(action).render :layout => false
  end
end
