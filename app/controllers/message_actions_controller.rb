# Controller to process interactive messages buttons clicks
class MessageActionsController < ApplicationController
  instrument_action :create
  protect_from_forgery with: :null_session

  def create
    return render json: {}, status: 404 unless slack_token_valid?
    render nothing: true, status: 204
  end

  private

  def slack_token
    ENV["SLACK_SLASH_COMMAND_TOKEN"]
  end

  def slack_token_valid?
    ActiveSupport::SecurityUtils.secure_compare(payload[:token], slack_token)
  end

  def payload
    @payload ||= JSON.parse(params[:payload]).with_indifferent_access
  end
end
