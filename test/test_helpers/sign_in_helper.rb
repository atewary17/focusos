# Signs in through the real login form, so tests exercise the same path as users.
module SignInHelper
  def sign_in(user, password: "password")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) { include SignInHelper }
