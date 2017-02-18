# Session controller for authenticating users with GitHub/Heroku/Hipchat
class SessionsController < ApplicationController
  include SessionsHelper
  # protect_from_forgery with: :null_session
  rescue_from StandardError, with: :say_oops
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

    Rails.logger.info "user: #{user.inspect}"

    user.save
    redirect_to after_successful_heroku_user_setup_path
  rescue ActiveRecord::RecordNotFound
    redirect_to "/?origin=#{omniauth_origin}"
  end

  # rubocop:enable Metrics/AbcSize
  def create_flock
    if params[:name] == "app.install"
      user = User.find_or_initialize_by(flock_user_id: params[:userId], flock_auth_token: params[:token])
      user.save
      session[:user_id] = user.id
      render nothing: true, status: 200
    elsif params[:name] == "client.slashCommand" && params[:command] == "heroku"
      Rails.logger.info "Slash Command: Redirected"
      Rails.logger.info "Creating Command"
      if flock_token_valid?
        Rails.logger.info "Flock token Valid"
        if current_user && current_user.heroku_uuid
          Rails.logger.info "Current User found"
          command = current_user.create_command_for(params, current_user)
          render json: command.default_response.to_json
        else
          Rails.logger.info "Not logged in"
          command = Command.from_params(params)
          render json: command.authenticate_heroku_response
        end
      else
        Rails.logger.info "Token not valid"
        render json: {}, status: 404
      end
    elsif params[:name] == "app.uninstall"
      destroy
    end
  end

  def complete
    Rails.logger.info "Completed installation"
    redirect_to :root
  end

  def destroy
    session.clear
    redirect_to root_url, notice: "Signed out!"
  end

  private

  def current_user
    @current_user ||= User.find_by(flock_user_id: params[:userId])
  end

  def flock_token
    ENV["FLOCK_OAUTH_SECRET"]
  end

  def flock_token_valid?
    if params[:name] == "client.slashCommand"
      ActiveSupport::SecurityUtils.secure_compare(params[:userId], current_user.flock_user_id)
    end
  end

  def say_oops(exception)
    Raven.capture_exception(exception)
    FlockPostback.for("Sorry there was a problem!", current_user)
  end

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
