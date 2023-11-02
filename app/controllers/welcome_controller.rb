class WelcomeController < ActionController::Base
  def index
  end

  def user_session
    render json: session
  end
end
