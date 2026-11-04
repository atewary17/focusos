require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "requires sign-in" do
    get account_path
    assert_redirected_to new_session_path
  end

  test "shows settings" do
    sign_in @user
    get account_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "updates name and time zone without touching the password" do
    sign_in @user
    patch account_path, params: { user: { name: "Asha Rao K", time_zone: "Asia/Tokyo", password: "", password_confirmation: "" } }

    assert_redirected_to account_path
    @user.reload
    assert_equal "Asha Rao K", @user.name
    assert_equal "Asia/Tokyo", @user.time_zone
    assert @user.authenticate("password"), "password should be unchanged"
  end

  test "changes the password" do
    sign_in @user
    patch account_path, params: { user: { name: @user.name, time_zone: @user.time_zone,
                                          password: "brand-new-pass", password_confirmation: "brand-new-pass" } }

    assert_redirected_to account_path
    assert @user.reload.authenticate("brand-new-pass")
  end

  test "shows errors for invalid settings" do
    sign_in @user
    patch account_path, params: { user: { name: "", time_zone: "Asia/Kolkata" } }
    assert_response 422
  end

  test "keeps the account when the password is wrong" do
    sign_in @user
    assert_no_difference("User.count") do
      delete account_path, params: { password: "not-my-password" }
    end
    assert_redirected_to account_path
  end

  test "deletes the account and its sessions with the right password" do
    sign_in @user
    assert_difference("User.count", -1) do
      delete account_path, params: { password: "password" }
    end
    assert_redirected_to new_session_path
    assert_equal 0, Session.where(user_id: @user.id).count
  end
end
