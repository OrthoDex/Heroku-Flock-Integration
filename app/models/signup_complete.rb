# Notifies the user that they're done signing up
class SignupComplete
  attr_reader :flock_user_id, :postback_url

  def self.notify(flock_user_id, postback_url)
    new(flock_user_id, postback_url).notify_user_of_success
  end

  def initialize(flock_user_id, postback_url)
    @flock_user_id = flock_user_id
    @postback_url = postback_url
  end

  def notify_user_of_success
    return unless user
    FlockPostback.for(message, postback_url)
  end

  def user
    User.find_by(flock_user_id: flock_user_id)
  end

  def name
    "<@#{user.flock_user_id}|#{user.flock_user_name}>"
  end

  def message
    text_response("#{name} you're all set. :tada:")
  end

  def text_response(text)
    { text: text, response_type: "in_channel" }
  end
end
