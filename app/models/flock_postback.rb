# Sends a Flock message to a given Flock url
class FlockPostback
  attr_reader :message, :url

  def self.for(message, url)
    new(message, url).postback_message
  end

  def initialize(message, url)
    @message = message
    @url = url
  end

  def postback_message
    response = client.post do |request|
      request.url callback_uri.path
      request.body = message.to_json
      request.headers["Content-Type"] = "application/json"
    end

    Rails.logger.info action: "command#postback_message", body: response.body
  rescue StandardError => e
    Rails.logger.info "Unable to post back to flock: '#{e.inspect}'"
  end

  def callback_uri
    @callback_uri ||= Addressable::URI.parse(url)
  end

  def client
    @client ||= Faraday.new(url: "https://api.flock.co/v1/") do |c|
      c.use :instrumentation
      c.use ZipkinTracer::FaradayHandler, "api.flock.co"
      c.adapter Faraday.default_adapter
    end
  end
end
