class ApplicationController < ActionController::Base
  before_action :clear_session_unless_jwt
  before_action :authenticate_request

  private

  def clear_session_unless_jwt
    session.clear unless jwt_present?
  end

  def authenticate_request
    jwt_authenticate if jwt_present?
    session_id_authenticate unless session[:current_user].present?
  end

  def jwt_present?
    request.headers["Authorization"].present?
  end

  def session_id_authenticate
    render_unauthorized("A valid session ID or JWT is required") and return if params[:session_id].blank?

    auth_response = Resource::Auth.poll(params[:session_id])
    render_unauthorized("Invalid session ID") and return if auth_response.nil?

    user_uuid = JSON.parse(auth_response, symbolize_names: true)[:vals][:context_user_uuid]
    set_user(user_uuid)
  end

  def set_user(uuid)
    response = Base.profile_request("#{Rails.application.config.service_url[:profile_v3]}/nucleus/profile/#{uuid}")
    user = response[:data][0]
    Session.set_user_on_session(user, session)
  end

  def jwt_authenticate
    token = request.headers["Authorization"].to_s.split(" ").last
    decoded = JsonWebToken.decode(token)
    set_user(decoded["uuid"])
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError => e
    render_unauthorized(e.message)
  end

  def render_unauthorized(message)
    render json: {errors: message}, status: :unauthorized
  end
end
