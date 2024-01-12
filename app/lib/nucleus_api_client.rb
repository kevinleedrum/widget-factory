# frozen_string_literal: true

# Wrapper for interacting with the Nucleus API
class NucleusApiClient
  def get_token(submitted_by_uuid)
    dev_api_token = get_dev_api_token(submitted_by_uuid)
    return nil if dev_api_token.nil?
    decrypt_token(dev_api_token)
  end

  def get_dev_api_token(submitted_by_uuid)
    Rails.cache.fetch("token-#{submitted_by_uuid}", expires_in: 12.hours, skip_nil: true) do
      jwt = JsonWebToken.encode({uuid: submitted_by_uuid})
      r = RestClient.get("#{Rails.application.config.nucleus_base}/api/v1/tokens/#{submitted_by_uuid}", {Authorization: "Bearer #{jwt}"})
      JSON.parse(r.body, symbolize_names: true)
    rescue => e
      Rails.logger.error "Token retrieval failed for uuid #{submitted_by_uuid}: #{e.message}"
      nil
    end
  end

  def decrypt_token(dev_api_token) # rubocop:disable Metrics/AbcSize
    decipher = OpenSSL::Cipher.new("aes-256-cbc")
    decipher.decrypt
    decipher.key = Digest::SHA256.digest(Rails.application.config.secret_key)
    decipher.iv = Base64.decode64(dev_api_token[:iv])
    decipher.update(Base64.decode64(dev_api_token[:encrypted_token])) + decipher.final
  rescue OpenSSL::Cipher::CipherError => e
    Rails.logger.error "Token decryption failed: #{e.message}"
    nil
  end
end
