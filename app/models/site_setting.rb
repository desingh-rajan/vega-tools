class SiteSetting < ApplicationRecord
  CATEGORIES = %w[general appearance contact sections features].freeze

  SYSTEM_KEYS = %w[
    site_info contact_info hero_section stats_section
    about_section social_links theme_config
  ].freeze

  # Associations
  belongs_to :updated_by, class_name: "User", optional: true

  # Active Storage for images (logo, carousel, etc.)
  has_one_attached :logo
  has_many_attached :images

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :value, presence: true

  # Scopes
  scope :public_settings, -> { where(is_public: true) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :system_settings, -> { where(is_system: true) }

  # Get by key with auto-seed for system settings
  def self.get(key)
    find_by(key: key) || (SYSTEM_KEYS.include?(key.to_s) ? seed_system_setting(key.to_s) : nil)
  end

  # Get value for a key (returns hash)
  def self.value_for(key)
    get(key)&.value || {}
  end

  # Bulk get multiple settings
  def self.get_all(*keys)
    keys.flatten.each_with_object({}) do |key, hash|
      hash[key.to_s] = value_for(key)
    end
  end

  # For Ransack search (Active Admin)
  def self.ransackable_attributes(auth_object = nil)
    %w[key category is_system is_public description created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[updated_by]
  end

  private

  def self.seed_system_setting(key)
    defaults = DEFAULTS[key]
    return nil unless defaults

    create!(
      key: key,
      category: defaults[:category],
      value: defaults[:value],
      is_system: true,
      is_public: defaults[:is_public] || false,
      description: defaults[:description]
    )
  end

  DEFAULTS = {
    "site_info" => {
      category: "general",
      is_public: true,
      description: "Basic site information",
      value: {
        "site_name" => "Vega Tools & Hardwares",
        "tagline" => "Building your dreams with quality tools",
        "description" => "Dindigul's #1 Tool Store - Authorized POLYMAK dealer",
        "website" => "https://vegatoolsandhardwares.in/"
      }
    },
    "contact_info" => {
      category: "contact",
      is_public: true,
      description: "Contact details",
      value: {
        "phone" => "095007 16588",
        "email" => "contact@vegatoolsandhardwares.in",
        "website" => "https://vegatoolsandhardwares.in/",
        "address" => "No. 583/4B, Dindigul - Trichy Bypass Road, Rajakkapatti, EB Colony, Dindigul District, Tamil Nadu 624004",
        "google_maps_url" => "https://maps.app.goo.gl/eQ6RmoxqpgrFpksp7",
        "store_hours" => "Monday - Saturday: 9 AM - 8 PM"
      }
    },
    "hero_section" => {
      category: "sections",
      is_public: true,
      description: "Hero section content",
      value: {
        "title_line1" => "Dindigul's #1 Tool Store",
        "title_line2" => "Premium Tools, Trusted Service",
        "subtitle" => "Authorized POLYMAK dealer in Dindigul | Professional power tools, precision hand tools & complete safety solutions"
      }
    },
    "stats_section" => {
      category: "sections",
      is_public: true,
      description: "Stats displayed on landing page",
      value: {
        "stat1" => { "number" => "4.8⭐", "label" => "Google Rating" },
        "stat2" => { "number" => "500+", "label" => "Power Tools" },
        "stat3" => { "number" => "100+", "label" => "Genuine Products" }
      }
    },
    "about_section" => {
      category: "sections",
      is_public: true,
      description: "About section content",
      value: {
        "title" => "About Vega Tools and Hardwares",
        "paragraphs" => [
          "Located on Trichy Road in Dindigul District, Tamil Nadu, Vega Tools and Hardwares is your trusted partner for professional power tools and safety equipment.",
          "With a 4.8-star rating and hundreds of satisfied customers, we serve contractors, builders, and industrial clients across Dindigul and surrounding regions."
        ],
        "features" => [
          "Authorized POLYMAK Dealer",
          "Complete Safety Equipment",
          "Professional Grade Tools",
          "Expert Technical Support"
        ]
      }
    },
    "social_links" => {
      category: "contact",
      is_public: true,
      description: "Social media links",
      value: {
        "whatsapp" => "https://wa.me/919500716588",
        "instagram" => "",
        "facebook" => ""
      }
    },
    "theme_config" => {
      category: "appearance",
      is_public: true,
      description: "Theme and appearance settings",
      value: {
        "primary_color" => "#f59e0b",
        "secondary_color" => "#1e293b",
        "font_family" => "Inter, system-ui, sans-serif"
      }
    }
  }.freeze
end
