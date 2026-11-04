class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_signed_in_user
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: "Too many attempts. Try again in a few minutes." }

  def new
    @user = User.new(time_zone: User::DEFAULT_TIME_ZONE)
  end

  def create
    @user = User.new(registration_params)

    unless invite_code_valid?
      @user.valid?
      @user.errors.add(:base, "Invite code is not valid")
      return render :new, status: 422
    end

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to FocusOS, #{@user.first_name}!"
    else
      render :new, status: 422
    end
  end

  private
    def registration_params
      params.expect(user: %i[name email_address password password_confirmation time_zone terms_accepted])
    end

    # Set SIGNUP_INVITE_CODE on Railway so only people you invite can sign up.
    # Leave it unset locally to sign up freely.
    def invite_code_valid?
      required = ENV["SIGNUP_INVITE_CODE"].to_s
      required.empty? || ActiveSupport::SecurityUtils.secure_compare(params[:invite_code].to_s.strip, required)
    end

    def redirect_signed_in_user
      redirect_to root_path if authenticated?
    end
end
