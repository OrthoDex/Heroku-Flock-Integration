# Sends a Flock message to a given Flock url
class FlockPostback
  FLOCK_API_URL="https://api.flock.co/v1/"
  attr_reader :message, :url

  def self.for(message, user)
    new(message, FLOCK_API_URL, user).postback_message
  end

  def initialize(message, url, user)
    @message = message
    @url = url
    @user = user
  end

  def postback_message
    response = client.post do |request|
      request.url callback_uri.path + "chat.sendMessage?to=#{@user.flock_user_id}&token=#{@user.flock_auth_token}"
      request.body = {text: @message}
      request.headers["Content-Type"] = "application/json"
    end

    Rails.logger.info action: "command#postback_message", body: response.body
  rescue StandardError => e
    Rails.logger.info "Unable to post back to flock: '#{e.inspect}'"
  end

  def callback_uri
    @callback_uri ||= Addressable::URI.parse(@url)
  end

  def client
    @client ||= Faraday.new(url: "https://api.flock.co/v1/") do |c|
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "api.flock.co"
      c.adapter Faraday.default_adapter
    end
  end
end
