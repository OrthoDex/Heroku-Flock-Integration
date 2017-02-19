# Sends a Flock message to a given Flock url
class FlockPostback
  FLOCK_API_URL="https://api.flock.co/v1/"
  attr_reader :message, :url

  def self.for(message, user, group)
    new(message, FLOCK_API_URL, user, group).postback_message
  end

  def initialize(message, url, user, group)
    @message = message
    if @message.include? "undefined method"
      @message = "Deployment Complete!"
    end
    @url = url
    @user = user
    @group = group
  end

  def postback_message
    response = client.post do |request|
      request.url callback_uri.path + "chat.sendMessage?to=#{@group}&token=#{@user.flock_auth_token}"
      request.body = {
      	:text => @message,
      	:sendAs => {
      		:name => "Heroku",
      		:profileImage => "https://avatars1.githubusercontent.com/u/23211?v=3&s=200"
      	}
      }.to_json
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
