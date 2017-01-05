# Module for handling User's tokens. Encrypting/Decrypting etc
module TokenManagement
  extend ActiveSupport::Concern

  included do
  end

  # Things exposed to the included class as class methods
  module ClassMethods
    def fernet_secret
      ENV["FERNET_SECRET"] ||
        raise("No FERNET_SECRET environmental variable set")
    end

    def fernet_secret_bytes
      fernet_secret.unpack("m0").first
    end

    def all_refreshable
      self.where("updated_at < :updated_at AND credentials_used_at < :used_at",
                 updated_at: 10.minutes.ago, used_at: 10.minutes.ago)
    end

    def refresh_all_oauth_tokens
      users = all_refreshable
      Rails.logger.info "Refreshing tokens for #{users.length} users..."

      users.each do |user|
        begin
          user.refresh_oauth_tokens
          Rails.logger.info "Tokens refreshed for #{user.heroku_email}"
        rescue StandardError
          msg = "Tokens not refreshed for #{user.heroku_email}"
          Rails.logger.info msg
          err = UserRefreshFailure.new(msg)
          Raven.capture_exception(err)
        end
      end
    end
  end
  class UserRefreshFailure < StandardError; end

  def rbnacl_reset
    @rbnacl_simple_box = nil
  end

  def rbnacl_simple_box
    @rbnacl_simple_box ||=
      RbNaCl::SimpleBox.from_secret_key(self.class.fernet_secret_bytes)
  end

  def rbnacl_encrypt_value(value)
    return if value.blank?
    Base64.encode64(rbnacl_simple_box.encrypt(value)).chomp
  end

  def rbnacl_decrypt_value(value)
    rbnacl_simple_box.decrypt(Base64.decode64(value))
  rescue RbNaCl::CryptoError, NoMethodError
    nil
  end

  def refresh_oauth_tokens
    refresh_heroku_oauth_token
    refresh_github_oauth_token
  end

  def reset_creds
    reset_github
    reset_heroku
    self.save
  end
end
