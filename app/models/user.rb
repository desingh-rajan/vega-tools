class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  # TODO: Enable OmniAuth when credentials are configured
  # :omniauthable, omniauth_providers: [:google_oauth2, :facebook]

  enum :role, { user: 0, admin: 1, super_admin: 2 }

  validates :role, presence: true
  validates :email, uniqueness: { allow_blank: true }
  validates :phone_number, uniqueness: { allow_blank: true },
                           format: { with: /\A[0-9]{10}\z/, message: "must be 10 digits" },
                           allow_blank: true
  validate :email_or_phone_present

  scope :admins, -> { where(role: [ :admin, :super_admin ]) }

  attr_accessor :login

  class << self
    def find_for_database_authentication(warden_conditions)
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

    def from_omniauth(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email = auth.info.email
        user.password = Devise.friendly_token[0, 20]
        user.name = auth.info.name
        user.avatar_url = auth.info.image
        user.role = :user
      end
    end

    def ransackable_attributes(_auth_object = nil)
      %w[name email phone_number role country_code provider created_at updated_at]
    end

    def ransackable_associations(_auth_object = nil)
      []
    end
  end

  def admin_access?
    admin? || super_admin?
  end

  def active_admin_access?
    admin_access?
  end

  def full_phone_number
    return nil unless phone_number.present?
    "#{country_code}#{phone_number}"
  end

  def email_required?
    false
  end

  def will_save_change_to_email?
    email.present? && super
  end

  private

  def email_or_phone_present
    return unless email.blank? && phone_number.blank?
    errors.add(:base, "Email or phone number must be provided")
  end
end
