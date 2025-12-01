class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # TODO: Enable OmniAuth when credentials are configured
  # :omniauthable, omniauth_providers: [ :google_oauth2, :facebook ]

  # Roles: user (default), admin, super_admin
  enum :role, { user: 0, admin: 1, super_admin: 2 }

  # Validations
  validates :role, presence: true
  validates :email, uniqueness: { allow_blank: true }
  validates :phone_number, uniqueness: { allow_blank: true }
  validate :email_or_phone_present
  validates :phone_number, format: { with: /\A[0-9]{10}\z/, message: "must be 10 digits" }, allow_blank: true

  # Scopes
  scope :admins, -> { where(role: [ :admin, :super_admin ]) }

  # Virtual attribute for login (email or phone)
  attr_accessor :login

  # Override Devise to allow login with email OR phone
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(
        "LOWER(email) = :value OR phone_number = :value",
        value: login.downcase.strip
      ).first
    elsif conditions.key?(:email) || conditions.key?(:phone_number)
      where(conditions.to_h).first
    end
  end

  # OmniAuth callback - find or create user from OAuth provider
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image
      user.role = :user # Default role for OAuth users
    end
  end

  # Check if user can access admin panel
  def admin_access?
    admin? || super_admin?
  end

  # For Active Admin authorization
  def active_admin_access?
    admin_access?
  end

  # Full phone number with country code
  def full_phone_number
    return nil unless phone_number.present?
    "#{country_code}#{phone_number}"
  end

  # Override Devise's email_required? to allow phone-only users
  def email_required?
    false
  end

  # Override Devise's email_changed? for phone-only users
  def will_save_change_to_email?
    email.present? && super
  end

  # For Ransack search (Active Admin)
  def self.ransackable_attributes(auth_object = nil)
    %w[name email phone_number role country_code provider created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def email_or_phone_present
    if email.blank? && phone_number.blank?
      errors.add(:base, "Email or phone number must be provided")
    end
  end
end
