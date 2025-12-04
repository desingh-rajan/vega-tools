class SiteSetting < ApplicationRecord
  CATEGORIES = %w[general appearance contact sections features].freeze

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

  DEFAULTS = load_defaults_from_yaml
  SYSTEM_KEYS = DEFAULTS.keys.map(&:to_s).freeze

  include HasProcessedImages

  belongs_to :updated_by, class_name: "User", optional: true

  has_one_attached :logo, service: Rails.env.production? ? :amazon_public : (Rails.env.development? ? :amazon_dev : :local)
  has_many_attached :images, service: Rails.env.production? ? :amazon_public : (Rails.env.development? ? :amazon_dev : :local)

  has_processed_images :logo
  has_processed_images :images

  validates :key, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :value, presence: true

  scope :public_settings, -> { where(is_public: true) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :system_settings, -> { where(is_system: true) }

  class << self
    def get(key)
      find_by(key: key) || (system_key?(key) ? seed_system_setting(key.to_s) : nil)
    end

    def value_for(key)
      record = find_by(key: key)
      return record.value if record.present?
      default_value_for(key)
    end

    def default_value_for(key)
      defaults = DEFAULTS[key.to_s] || DEFAULTS[key.to_sym]
      return {} unless defaults
      (defaults[:value] || {}).deep_stringify_keys
    end

    def default_config_for(key)
      DEFAULTS[key.to_s] || DEFAULTS[key.to_sym]
    end

    def system_key?(key)
      SYSTEM_KEYS.include?(key.to_s)
    end

    def get_all(*keys)
      keys.flatten.each_with_object({}) do |key, hash|
        hash[key.to_s] = value_for(key)
      end
    end

    def reset_to_default(key)
      record = find_by(key: key)
      return seed_system_setting(key.to_s) unless record

      defaults = default_config_for(key)
      return record unless defaults

      record.update!(value: defaults[:value].deep_stringify_keys)
      record
    end

    def reset_all_to_defaults
      SYSTEM_KEYS.each { |key| reset_to_default(key) }
    end

    def seed_all_system_settings
      SYSTEM_KEYS.each { |key| get(key) }
    end

    def ransackable_attributes(_auth_object = nil)
      %w[key category is_system is_public description created_at updated_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[updated_by]
    end

    private

    def seed_system_setting(key)
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
end
