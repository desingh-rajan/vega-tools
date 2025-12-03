class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  # Active Admin authentication - requires admin or super_admin role
  def authenticate_admin_user!
    authenticate_user!
    unless current_user&.admin_access?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end

  # Access denied handler for Active Admin
  def access_denied(exception)
    redirect_to root_path, alert: exception.message
  end
end
