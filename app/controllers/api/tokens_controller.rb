class Api::TokensController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /api/tokens/clear/:uuid
  def clear
    Rails.cache.delete("token-#{params[:uuid]}")
    render json: {success: true}
  end
end
