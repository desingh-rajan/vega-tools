module Api
  module V1
    class SiteSettingsController < BaseController
      # GET /api/v1/site_settings
      # Returns all public site settings for the app
      def index
        settings = {}

        SiteSetting.all.each do |setting|
          settings[setting.key] = setting.value
        end

        render_success(settings)
      end

      # GET /api/v1/site_settings/:key
      # Returns a specific setting by key
      def show
        setting = SiteSetting.find_by!(key: params[:key])

        render_success({
          key: setting.key,
          value: setting.value
        })
      end

      # GET /api/v1/site_settings/homepage
      # Returns all settings needed for homepage in one call
      def homepage
        render_success({
          site_info: SiteSetting.value_for("site_info"),
          hero_section: SiteSetting.value_for("hero_section"),
          featured_categories: featured_categories_data,
          featured_products: featured_products_data,
          carousel_images: SiteSetting.value_for("carousel_images"),
          contact_info: SiteSetting.value_for("contact_info"),
          social_links: SiteSetting.value_for("social_links"),
          footer_content: SiteSetting.value_for("footer_content")
        })
      end

      # GET /api/v1/site_settings/app_config
      # Returns essential app configuration
      def app_config
        site_info = SiteSetting.value_for("site_info")
        contact_info = SiteSetting.value_for("contact_info")
        social_links = SiteSetting.value_for("social_links")

        render_success({
          app_name: site_info["name"] || "Vega Tools",
          tagline: site_info["tagline"],
          logo_url: site_info["logo_url"],
          currency: "INR",
          currency_symbol: "₹",
          contact: {
            phone: contact_info["phone"],
            email: contact_info["email"],
            whatsapp: contact_info["whatsapp"]
          },
          social_links: social_links,
          meta: SiteSetting.value_for("meta_defaults")
        })
      end

      private

      def featured_categories_data
        featured_setting = SiteSetting.value_for("featured_categories")
        featured_ids = featured_setting.is_a?(Array) ? featured_setting : []

        if featured_ids.present?
          categories = Category.active.where(id: featured_ids)
        else
          # Fallback: root categories with products
          categories = Category.active.roots
                              .left_joins(:products)
                              .group("categories.id")
                              .having("COUNT(products.id) > 0")
                              .limit(6)
        end

        categories.map do |c|
          {
            id: c.id,
            name: c.name,
            slug: c.slug,
            icon_url: c.icon_image.attached? ? url_for(c.icon_image) : nil,
            products_count: c.products.published.count
          }
        end
      end

      def featured_products_data
        featured_setting = SiteSetting.value_for("featured_products")
        featured_ids = featured_setting.is_a?(Array) ? featured_setting : []

        if featured_ids.present?
          products = Product.published.where(id: featured_ids).includes(:category)
        else
          # Fallback: newest products
          products = Product.published.includes(:category).order(created_at: :desc).limit(8)
        end

        products.map do |p|
          {
            id: p.id,
            name: p.name,
            slug: p.slug,
            price: p.price.to_f,
            discounted_price: p.discounted_price&.to_f,
            effective_price: p.effective_price.to_f,
            on_sale: p.on_sale?,
            image_url: p.images.attached? ? url_for(p.images.first) : nil,
            category_name: p.category&.name
          }
        end
      end
    end
  end
end
