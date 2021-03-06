class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :yield_or_default
  helper_method :current_user
  helper_method :current_ability
  helper :all # include all helpers, all the time

  rescue_from CanCan::AccessDenied do |exception|
     redirect_to :controller => 'user_sessions', :action => 'new'
  end

  private
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    @current_user = current_user_session && current_user_session.record
  end

  # Yield the content for a given block. If the block yiels nothing, the optionally specified default text is shown.
  #
  #   yield_or_default(:user_status)
  #
  #   yield_or_default(:sidebar, "Sorry, no sidebar")
  #
  # +target+ specifies the object to yield.
  # +default_message+ specifies the message to show when nothing is yielded. (Default: "")
  def yield_or_default(message, default_message = "")
    message.nil? ? default_message : message
  end

end
