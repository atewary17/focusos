require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "issue! returns the plain token once and stores only its digest" do
    record, plain = ApiToken.issue!(user: users(:one), device: devices(:one_phone), name: "Test")

    assert plain.start_with?(ApiToken::PREFIX)
    assert_equal ApiToken.digest(plain), record.token_digest
    assert_not_includes record.attributes.values.map(&:to_s), plain
  end

  test "authenticate finds an active token" do
    assert_equal api_tokens(:one_phone), ApiToken.authenticate("fo_test_one")
  end

  test "authenticate rejects revoked, expired, unknown and blank tokens" do
    assert_nil ApiToken.authenticate("fo_test_revoked")
    assert_nil ApiToken.authenticate("fo_test_expired")
    assert_nil ApiToken.authenticate("fo_unknown")
    assert_nil ApiToken.authenticate("")
    assert_nil ApiToken.authenticate(nil)
  end

  test "touch_last_used! writes at most once a minute" do
    token = api_tokens(:one_phone)
    token.touch_last_used!
    first = token.reload.last_used_at
    assert first

    travel 30.seconds do
      token.touch_last_used!
      assert_equal first, token.reload.last_used_at
    end

    travel 2.minutes do
      token.touch_last_used!
      assert_operator token.reload.last_used_at, :>, first
    end
  end
end
