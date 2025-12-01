module Api
  module V1
    class CategoriesController < BaseController
      # GET /api/v1/categories
      # Returns all root categories with their children
      def index
        categories = Category.active.roots.includes(:children).ordered

        render_success(categories.map { |c| category_json(c, include_children: true) })
      end

      # GET /api/v1/categories/:id
      # Returns a single category with full details
      def show
        category = Category.active.find(params[:id])

        render_success(category_json(category, include_children: true, include_ancestors: true))
      end

      # GET /api/v1/categories/:id/products
      # Returns products in a category (including subcategory products)
      def products
        category = Category.active.find(params[:id])

        # Get all descendant category IDs (filter active ones from array)
        all_category_ids = [ category.id ] + category.descendants.select(&:active).map(&:id)

        products = Product.published
                         .where(category_id: all_category_ids)
                         .includes(:category)
                         .ordered

        result = paginate(products)

        render_success(
          result[:items].map { |p| product_json(p) },
          meta: result[:meta]
        )
      end

      # GET /api/v1/categories/tree
      # Returns full category tree for navigation
      def tree
        categories = Category.active.roots.includes(children: { children: :children }).ordered

        render_success(categories.map { |c| category_tree_json(c) })
      end

      # GET /api/v1/categories/featured
      # Returns featured categories for homepage
      def featured
        featured_setting = SiteSetting.value_for("featured_categories")
        featured_ids = featured_setting.is_a?(Array) ? featured_setting : []

        if featured_ids.present?
          categories = Category.active.where(id: featured_ids)
          render_success(categories.map { |c| category_json(c) })
        else
          # Fallback: return root categories with most products
          categories = Category.active.roots
                              .left_joins(:products)
                              .group("categories.id")
                              .order("COUNT(products.id) DESC")
                              .limit(6)
          render_success(categories.map { |c| category_json(c) })
        end
      end

      private

      def category_json(category, include_children: false, include_ancestors: false)
        json = {
          id: category.id,
          name: category.name,
          slug: category.slug,
          description: category.description,
          icon_url: category.icon_image.attached? ? url_for(category.icon_image) : nil,
          parent_id: category.parent_id,
          products_count: category.products.published.count,
          full_path: category.full_path
        }

        if include_children
          active_children = category.children.select(&:active)
          if active_children.any?
            json[:children] = active_children.sort_by { |c| [ c.position || 0, c.name ] }.map { |c| category_json(c) }
          end
        end

        if include_ancestors
          json[:ancestors] = category.ancestors.map do |a|
            { id: a.id, name: a.name, slug: a.slug }
          end
        end

        json
      end

      def category_tree_json(category)
        {
          id: category.id,
          name: category.name,
          slug: category.slug,
          icon_url: category.icon_image.attached? ? url_for(category.icon_image) : nil,
          children: category.children.select(&:active).sort_by { |c| [ c.position || 0, c.name ] }.map { |c| category_tree_json(c) }
        }
      end

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          slug: product.slug,
          sku: product.sku,
          brand: product.brand,
          price: product.price.to_f,
          discounted_price: product.discounted_price&.to_f,
          effective_price: product.effective_price.to_f,
          on_sale: product.on_sale?,
          discount_percentage: product.discount_percentage,
          image_url: product.images.attached? ? url_for(product.images.first) : nil,
          category: product.category ? {
            id: product.category.id,
            name: product.category.name,
            slug: product.category.slug
          } : nil
        }
      end
    end
  end
end
