require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      name: "Meera Iyer",
      email_address: "meera@example.com",
      password: "longenough",
      password_confirmation: "longenough",
      time_zone: "Asia/Kolkata",
      terms_accepted: true
    }.merge(overrides)
  end

  test "fixture users are valid" do
    assert users(:one).valid?
    assert users(:two).valid?
  end

  test "creates a user and records consent time" do
    user = User.create!(valid_attributes)
    assert_not_nil user.consented_at
  end

  test "normalizes email and name" do
    user = User.new(valid_attributes(email_address: "  Meera@Example.COM ", name: "  Meera   Iyer "))
    assert_equal "meera@example.com", user.email_address
    assert_equal "Meera Iyer", user.name
  end

  test "requires consent on sign-up" do
    user = User.new(valid_attributes(terms_accepted: false))
    assert_not user.valid?
    assert_includes user.errors[:terms_accepted], "must be accepted to create an account"
  end

  test "does not require consent again on update" do
    user = users(:one)
    assert user.update(name: "Asha R")
  end

  test "rejects unknown time zones" do
    user = User.new(valid_attributes(time_zone: "Mars/Olympus"))
    assert_not user.valid?
    assert user.errors.added?(:time_zone, "is not a valid time zone")
  end

  test "requires a password of at least 8 characters" do
    user = User.new(valid_attributes(password: "short", password_confirmation: "short"))
    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "rejects a duplicate email regardless of case" do
    user = User.new(valid_attributes(email_address: "ONE@example.com"))
    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :taken)
  end

  test "first name is the first word of the name" do
    assert_equal "Asha", users(:one).first_name
  end

  test "time zone options use IANA identifiers" do
    assert_includes User.time_zone_ids, "Asia/Kolkata"
    assert_equal User.time_zone_ids.size, User.time_zone_options.size
  end
end
