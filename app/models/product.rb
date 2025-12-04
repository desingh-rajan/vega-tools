class Product < ApplicationRecord
  belongs_to :category, optional: true

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discounted_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :discounted_price_less_than_price

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_brand, ->(brand) { where(brand: brand) }
  scope :uncategorized, -> { where(category_id: nil) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :price_between, ->(min, max) { where(price: min..max) }

  class << self
    def ransackable_attributes(_auth_object = nil)
      %w[name slug sku description price discounted_price brand published category_id created_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[category]
    end

    def available_brands
      where.not(brand: [ nil, "" ]).distinct.pluck(:brand).sort
    end
  end

  def discount_percentage
    return 0 unless discounted_price.present? && price.present? && price > 0
    ((price - discounted_price) / price * 100).round
  end

  def effective_price
    discounted_price.presence || price
  end

  def on_sale?
    discounted_price.present? && discounted_price < price
  end

  def image_url(variant = :original, index = 0)
    return nil if slug.blank?
    suffix = index.zero? ? "" : "_#{index}"
    "#{image_base_url}/#{slug}/#{variant}#{suffix}.webp"
  end

  def thumbnail_url(index = 0)
    image_url(:thumbnail, index)
  end

  def original_url(index = 0)
    image_url(:original, index)
  end

  def all_image_urls(variant = :original)
    (0...image_count).map { |i| image_url(variant, i) }
  end

  def all_thumbnail_urls
    all_image_urls(:thumbnail)
  end

  def has_images?
    image_count.positive?
  end

  def image_count
    specifications&.dig("image_count") || 0
  end

  private

  def image_base_url
    Rails.configuration.x.s3_images_base_url
  end

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 1

    while Product.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def discounted_price_less_than_price
    return unless discounted_price.present? && price.present? && discounted_price >= price
    errors.add(:discounted_price, "must be less than original price")
  end
end
