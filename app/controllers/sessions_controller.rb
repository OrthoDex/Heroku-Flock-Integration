# Session controller for authenticating users with GitHub/Heroku/Hipchat
class SessionsController < ApplicationController
  include SessionsHelper
  skip_before_action :verify_authenticity_token, only: [:create_flock]

  def create_github
    user = User.find(session[:user_id])
    user.github_login = omniauth_info["info"]["nickname"]
    user.github_token = omniauth_info["credentials"]["token"]

    user.save
    redirect_to after_successful_heroku_user_setup_path
  rescue ActiveRecord::RecordNotFound
    redirect_to "/?origin=#{omniauth_origin}"
  end

  # rubocop:disable Metrics/AbcSize
  def create_heroku
    user = User.find(session[:user_id])
    user.heroku_uuid  = omniauth_info["uid"]
    user.heroku_email = omniauth_info["info"]["email"]
    user.heroku_token = omniauth_info["credentials"]["token"]
    user.heroku_refresh_token = omniauth_refresh_token
    user.heroku_expires_at    = omniauth_expiration

    user.save
  rescue ActiveRecord::RecordNotFound
    redirect_to "/?origin=#{omniauth_origin}"
  end
  # rubocop:enable Metrics/AbcSize

  def create_flock
    if params[:name] == "app.install"
      user = User.find_or_initialize_by(flock_user_id: params[:userId])
      user.save
      session[:user_id] = user.id
      render nothing: true, status: 200
    elsif params[:name] == "client.slashCommand" && params[:command] == "heroku"
      redirect_to commands_path
    end
  end

  def complete
    @after_success_url = "https://flock.com/messages"
    if params[:origin]
      decoded = decoded_params_origin

      @after_success_url = decoded[:uri] if decoded[:uri] =~ /^flock:/

      command = Command.find(decoded[:token])
      if command
        SignupCompleteJob.perform_later(user_id: session[:user_id],
                                        command_id: command.id)
      end
    end
  rescue StandardError, ActiveRecord::RecordNotFound
    nil
  end

  def destroy
    session.clear
    redirect_to root_url, notice: "Signed out!"
  end

  private

  def after_successful_heroku_user_setup_path
    "/auth/complete?origin=#{omniauth_origin}"
  end

  def after_successful_flock_user_setup_path
    if decoded_omniauth_origin_provider
      "/auth/#{decoded_omniauth_origin_provider}?origin=#{omniauth_origin}"
    else
      "/auth/heroku?origin=#{omniauth_origin}"
    end
  end
end
