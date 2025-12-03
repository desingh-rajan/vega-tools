class SiteSetting < ApplicationRecord
  CATEGORIES = %w[general appearance contact sections features].freeze

  # Load defaults from YAML files (config/site_settings/*.yml)
  # This is memoized and loaded once at boot time
  def self.load_defaults_from_yaml
    defaults = {}
    yaml_dir = Rails.root.join("config", "site_settings")

    Dir.glob(yaml_dir.join("*.yml")).each do |file|
      yaml_content = YAML.load_file(file, permitted_classes: [ Symbol ]) || {}
      yaml_content.each do |key, config|
        defaults[key] = config.deep_symbolize_keys
      end
    end

    defaults.freeze
  end

  # Memoized DEFAULTS loaded from YAML
  DEFAULTS = load_defaults_from_yaml

  # System keys are all keys defined in YAML defaults
  SYSTEM_KEYS = DEFAULTS.keys.map(&:to_s).freeze

  include HasProcessedImages

  # Associations
  belongs_to :updated_by, class_name: "User", optional: true

  # Active Storage for images (logo, carousel, etc.)
  # Production: public S3 for direct URLs | Development: S3 dev folder | Test: local disk
  has_one_attached :logo, service: Rails.env.production? ? :amazon_public : (Rails.env.development? ? :amazon_dev : :local)
  has_many_attached :images, service: Rails.env.production? ? :amazon_public : (Rails.env.development? ? :amazon_dev : :local)

  # Enable WebP processing for logo and images
  has_processed_images :logo
  has_processed_images :images

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :value, presence: true

  # Scopes
  scope :public_settings, -> { where(is_public: true) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :system_settings, -> { where(is_system: true) }

  # Get by key with auto-seed for system settings
  # Returns the record (or creates it from defaults if it's a system setting)
  def self.get(key)
    find_by(key: key) || (system_key?(key) ? seed_system_setting(key.to_s) : nil)
  end

  # Get value for a key - ALWAYS returns a value
  # Priority: database value > YAML default > empty hash
  # This ensures defaults are ALWAYS available even if admin deletes the setting
  def self.value_for(key)
    record = find_by(key: key)
    return record.value if record.present?

    # Fallback to YAML defaults (bulletproof)
    default_value_for(key)
  end

  # Get the default value for a key from YAML
  def self.default_value_for(key)
    defaults = DEFAULTS[key.to_s] || DEFAULTS[key.to_sym]
    return {} unless defaults

    # YAML stores as symbol keys, we return stringified for consistency
    (defaults[:value] || {}).deep_stringify_keys
  end

  # Get full default config (category, description, value, etc.)
  def self.default_config_for(key)
    DEFAULTS[key.to_s] || DEFAULTS[key.to_sym]
  end

  # Check if a key is a system setting
  def self.system_key?(key)
    SYSTEM_KEYS.include?(key.to_s)
  end

  # Bulk get multiple settings (always returns values)
  def self.get_all(*keys)
    keys.flatten.each_with_object({}) do |key, hash|
      hash[key.to_s] = value_for(key)
    end
  end

  # Reset a setting to its default value
  def self.reset_to_default(key)
    record = find_by(key: key)
    return seed_system_setting(key.to_s) unless record

    defaults = default_config_for(key)
    return record unless defaults

    record.update!(value: defaults[:value].deep_stringify_keys)
    record
  end

  # Reset ALL system settings to defaults
  def self.reset_all_to_defaults
    SYSTEM_KEYS.each { |key| reset_to_default(key) }
  end

  # Seed all system settings (useful in seeds.rb or rake task)
  def self.seed_all_system_settings
    SYSTEM_KEYS.each { |key| get(key) }
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
    defaults = default_config_for(key)
    return nil unless defaults

    create!(
      key: key,
      category: defaults[:category].to_s,
      value: defaults[:value].deep_stringify_keys,
      is_system: true,
      is_public: defaults[:is_public] || false,
      description: defaults[:description].to_s
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to seed setting #{key}: #{e.message}"
    nil
  end
end
