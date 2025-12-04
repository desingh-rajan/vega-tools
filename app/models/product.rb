class Product < ApplicationRecord
  include S3WebpUploader::ImageHelpers

  # Aliases for backward compatibility with views
  alias_method :thumbnail_url, :s3_thumbnail_url
  alias_method :original_url, :s3_original_url
  alias_method :image_count, :s3_image_count
  alias_method :has_images?, :s3_has_images?

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

  private

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
