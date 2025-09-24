class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  def current_user
    @current_user
  end

  def authenticate_user!
    render status: :unauthorized unless current_user
  end
end
