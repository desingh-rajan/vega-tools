require "test_helper"
require "ostruct"

class UserTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @regular_user = users(:regular_user)
  end

  # Validations
  test "valid user with email" do
    user = User.new(
      email: "new@example.com",
      password: "password123",
      role: :user
    )
    assert user.valid?
  end

  test "valid user with phone only" do
    user = User.new(
      phone_number: "9876543299",
      password: "password123",
      role: :user
    )
    assert user.valid?
  end

  test "invalid without email and phone" do
    user = User.new(password: "password123", role: :user)
    assert_not user.valid?
    assert_includes user.errors[:base], "Email or phone number must be provided"
  end

  test "invalid with duplicate email" do
    user = User.new(
      email: @admin.email,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "invalid with duplicate phone_number" do
    user = User.new(
      phone_number: @admin.phone_number,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:phone_number], "has already been taken"
  end

  test "phone_number must be 10 digits" do
    user = User.new(email: "test@test.com", phone_number: "123", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:phone_number], "must be 10 digits"
  end

  test "phone_number allows blank" do
    user = User.new(email: "test@test.com", password: "password123")
    assert user.valid?
  end

  # Role enum
  test "default role is user" do
    user = User.new(email: "new@test.com", password: "password123")
    assert_equal "user", user.role
  end

  test "can assign admin role" do
    user = User.new(email: "admin@test.com", password: "password123", role: :admin)
    assert user.admin?
  end

  test "can assign super_admin role" do
    user = User.new(email: "super@test.com", password: "password123", role: :super_admin)
    assert user.super_admin?
  end

  # Admin access
  test "admin_access? returns true for admin" do
    @admin.role = :admin
    assert @admin.admin_access?
  end

  test "admin_access? returns true for super_admin" do
    assert @admin.admin_access?  # fixture is super_admin
  end

  test "admin_access? returns false for regular user" do
    assert_not @regular_user.admin_access?
  end

  test "active_admin_access? delegates to admin_access?" do
    assert @admin.active_admin_access?
    assert_not @regular_user.active_admin_access?
  end

  # Phone helpers
  test "full_phone_number combines country code and number" do
    user = User.new(phone_number: "9876543210", country_code: "+91")
    assert_equal "+919876543210", user.full_phone_number
  end

  test "full_phone_number returns nil when no phone" do
    user = User.new(email: "test@test.com")
    assert_nil user.full_phone_number
  end

  # Scopes
  test "admins scope returns admin and super_admin users" do
    admin_user = User.create!(email: "newadmin@test.com", password: "password123", role: :admin)
    admins = User.admins

    assert_includes admins, @admin
    assert_includes admins, admin_user
    refute_includes admins, @regular_user
  end

  # Devise overrides
  test "email_required? returns false" do
    user = User.new
    assert_not user.email_required?
  end

  test "find_for_database_authentication works with email" do
    found = User.find_for_database_authentication(login: @admin.email)
    assert_equal @admin, found
  end

  test "find_for_database_authentication works with phone" do
    found = User.find_for_database_authentication(login: @admin.phone_number)
    assert_equal @admin, found
  end

  test "find_for_database_authentication is case insensitive for email" do
    found = User.find_for_database_authentication(login: @admin.email.upcase)
    assert_equal @admin, found
  end

  test "find_for_database_authentication returns nil for non-existent login" do
    found = User.find_for_database_authentication(login: "nonexistent@test.com")
    assert_nil found
  end

  # OmniAuth
  test "from_omniauth creates new user" do
    auth = OpenStruct.new(
      provider: "google_oauth2",
      uid: "12345",
      info: OpenStruct.new(
        email: "oauth@test.com",
        name: "OAuth User",
        image: "https://example.com/avatar.jpg"
      )
    )

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth)
      assert_equal "oauth@test.com", user.email
      assert_equal "OAuth User", user.name
      assert_equal "google_oauth2", user.provider
      assert_equal "12345", user.uid
      assert user.user?  # Default role
    end
  end

  test "from_omniauth finds existing user" do
    auth = OpenStruct.new(
      provider: "google_oauth2",
      uid: "existing123",
      info: OpenStruct.new(email: "existing@test.com", name: "Existing", image: nil)
    )

    # Create user first
    existing = User.from_omniauth(auth)

    # Should find, not create
    assert_no_difference "User.count" do
      found = User.from_omniauth(auth)
      assert_equal existing.id, found.id
    end
  end
end
