class JsonWebToken
  def self.encode(payload)
    JWT.encode(payload, Rails.application.config.secret_key)
  end

  def self.decode(token)
    decoded = JWT.decode(token, Rails.application.config.secret_key)[0]
    HashWithIndifferentAccess.new decoded
  end
end
