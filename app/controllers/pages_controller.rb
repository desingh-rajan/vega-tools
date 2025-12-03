class PagesController < ApplicationController
  def home
    # Load all landing page settings with bulletproof defaults
    # SiteSetting.value_for ALWAYS returns a value (DB or YAML default)
    @site_info = SiteSetting.value_for("site_info")
    @contact_info = SiteSetting.value_for("contact_info")
    @hero_section = SiteSetting.value_for("hero_section")
    @hero_carousel = SiteSetting.value_for("hero_carousel")
    @stats_section = SiteSetting.value_for("stats_section")
    @about_section = SiteSetting.value_for("about_section")
    @social_links = SiteSetting.value_for("social_links")
    @theme_config = SiteSetting.value_for("theme_config")
    @products_section = SiteSetting.value_for("products_section")
    @featured_categories_config = SiteSetting.value_for("featured_categories")

    # Load categories with their products for homepage display
    # Get categories that have products, ordered by position
    @featured_categories = load_featured_categories
  end

  private

  def load_featured_categories
    # Get configured featured categories or fall back to categories with products
    config = @featured_categories_config["categories"] || []

    if config.present?
      # Load configured categories in order
      slugs = config.map { |c| c["slug"] }
      categories = Category.where(slug: slugs).includes(:products).index_by(&:slug)

      config.filter_map do |cat_config|
        category = categories[cat_config["slug"]]
        next unless category

        products = category.products.published.limit(6)
        next if products.empty?

        {
          category: category,
          title: cat_config["title"] || category.name,
          description: cat_config["description"] || category.description,
          products: products
        }
      end
    else
      # Fallback: get categories that have published products
      Category.active.ordered
        .joins(:products)
        .where(products: { published: true })
        .distinct
        .limit(6)
        .map do |category|
          products = category.products.published.limit(6)
          {
            category: category,
            title: category.name,
            description: category.description,
            products: products
          }
        end
    end
  end
end
