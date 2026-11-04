class AccountsController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(account_params)
      redirect_to account_path, notice: "Settings saved."
    else
      render :show, status: 422
    end
  end

  # Deletes the user and everything that belongs to them (dependent: :destroy).
  def destroy
    if @user.authenticate(params[:password].to_s)
      @user.destroy!
      cookies.delete(:session_id)
      reset_session
      redirect_to new_session_path, notice: "Your account and all its data have been deleted."
    else
      redirect_to account_path, alert: "That password didn't match. Your account was not deleted."
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def account_params
      attrs = params.expect(user: %i[name time_zone password password_confirmation])
      if attrs[:password].blank?
        attrs.delete(:password)
        attrs.delete(:password_confirmation)
      end
      attrs
    end
end
