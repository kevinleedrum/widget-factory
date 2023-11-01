class Api::JwtController < ActionController::Base
  skip_before_action :verify_authenticity_token

  # POST /api/jwt
  def index
    service = "#{Rails.application.config.service_url[:profile_v2]}/#{params[:uuid]}/validate_token"
    sr = WmsResource::SecureRequest.new("profile")
    salt = "#{Base64.decode64(params[:password])}:#{params[:uuid]}"
    check = Digest::SHA512.hexdigest(Base64.encode64(Digest::SHA512.hexdigest(salt)))

    begin
      RestClient.post(service, {
        sr_hash: sr.generate_hash,
        sr_timestamp: sr.timestamp,
        check: check
      })
      time = Time.now + 1.hour.to_i
      token = JsonWebToken.encode({uuid: params[:uuid], exp: time.to_i})
      render json: {token: token, exp: time.strftime("%m-%d-%Y %H:%M")}, status: :ok
    rescue RestClient::ExceptionWithResponse => e
      render json: {message: e.message}, status: :unauthorized
    end
  end
end
