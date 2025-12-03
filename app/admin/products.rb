ActiveAdmin.register Product do
  menu priority: 4, label: "Products"

  permit_params :name, :slug, :sku, :description, :price, :discounted_price,
                :brand, :published, :category_id, :specifications

  # Filters
  filter :name
  filter :sku
  filter :brand, as: :select, collection: -> { Product.available_brands }
  filter :category, as: :select, collection: -> { Category.ordered.map { |c| [ c.full_path, c.id ] } }
  filter :published
  filter :price
  filter :created_at

  # Scope tabs
  scope :all
  scope :published, default: true
  scope :unpublished
  scope :uncategorized

  # Index page
  index do
    selectable_column
    id_column
    column :image do |product|
      if product.has_images?
        image_tag product.thumbnail_url, width: 50, height: 50, style: "object-fit: cover;"
      else
        "-"
      end
    end
    column :name do |product|
      link_to product.name.truncate(40), admin_product_path(product)
    end
    column :sku
    column :brand
    column :category do |product|
      product.category ? link_to(product.category.name, admin_category_path(product.category)) : status_tag("Uncategorized", class: "warning")
    end
    column :price do |product|
      if product.on_sale?
        span style: "text-decoration: line-through; color: #999;" do
          text_node number_to_currency(product.price, unit: "₹")
        end
        span " → ", style: "color: #666;"
        span number_to_currency(product.discounted_price, unit: "₹"), style: "color: green; font-weight: bold;"
        span " (#{product.discount_percentage}% off)", style: "color: green; font-size: 0.8em;"
      else
        number_to_currency(product.price, unit: "₹")
      end
    end
    column :published do |product|
      status_tag product.published? ? "Published" : "Draft", class: product.published? ? "yes" : "no"
    end
    column :created_at
    actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :sku
      row :brand
      row :category do |product|
        product.category ? link_to(product.category.full_path, admin_category_path(product.category)) : "-"
      end
      row :description
      row :price do |product|
        number_to_currency(product.price, unit: "₹")
      end
      row :discounted_price do |product|
        product.discounted_price ? number_to_currency(product.discounted_price, unit: "₹") : "-"
      end
      row :discount_percentage do |product|
        product.on_sale? ? "#{product.discount_percentage}%" : "-"
      end
      row :effective_price do |product|
        number_to_currency(product.effective_price, unit: "₹")
      end
      row :specifications do |product|
        if product.specifications.present?
          pre JSON.pretty_generate(product.specifications.except("image_count"))
        else
          "-"
        end
      end
      row :published do |product|
        status_tag product.published? ? "Published" : "Draft", class: product.published? ? "yes" : "no"
      end
      row :images do |product|
        render partial: "admin/products/images_gallery", locals: { product: product }
      end
      row :created_at
      row :updated_at
    end

    panel "Upload New Images" do
      render partial: "admin/products/upload_form", locals: { product: resource }
    end
  end

  # Form
  form do |f|
    f.inputs "Product Details" do
      f.input :name
      f.input :slug, hint: "Auto-generated from name if left blank"
      f.input :sku
      f.input :brand
      f.input :category, as: :select,
              collection: Category.ordered.map { |c| [ c.full_path, c.id ] },
              include_blank: "-- Uncategorized --"
      f.input :description, as: :text
    end

    f.inputs "Pricing" do
      f.input :price, hint: "Original price in ₹"
      f.input :discounted_price, hint: "Sale price (leave blank if not on sale)"
    end

    f.inputs "Specifications (JSON)" do
      f.input :specifications, as: :text, input_html: { rows: 8 },
              hint: "JSON format, e.g., {\"color\": \"Red\", \"weight\": \"2kg\"}"
    end

    if f.object.persisted?
      f.inputs "Current Images" do
        if f.object.has_images?
          f.object.image_count.times do |i|
            div style: "display: inline-block; margin: 10px; text-align: center;" do
              image_tag f.object.thumbnail_url(i), width: 80, style: "border: 1px solid #ddd;"
            end
          end
          para "Use the Show page to upload new images or delete existing ones.", style: "color: #666; margin-top: 10px;"
        else
          para "No images uploaded yet. Save the product first, then use the Show page to upload images."
        end
      end
    else
      f.inputs "Images" do
        para "Save the product first, then you can upload images from the Show page."
      end
    end

    f.inputs "Publishing" do
      f.input :published, hint: "Only published products are visible to customers"
    end

    f.actions
  end

  # Member actions for image upload/delete
  member_action :upload_images, method: :post do
    if params[:images].present?
      uploader = ProductImageUploader.new(resource)
      uploaded = uploader.upload_multiple(params[:images])

      if uploaded.any?
        redirect_to admin_product_path(resource), notice: "#{uploaded.count} image(s) uploaded successfully!"
      else
        redirect_to admin_product_path(resource), alert: "Failed to upload images."
      end
    else
      redirect_to admin_product_path(resource), alert: "No images selected."
    end
  end

  member_action :delete_image, method: :delete do
    index = params[:index].to_i
    uploader = ProductImageUploader.new(resource)
    uploader.delete(index)

    redirect_to admin_product_path(resource), notice: "Image #{index + 1} deleted from S3!"
  end

  member_action :replace_image, method: :patch do
    index = params[:index].to_i
    if params[:image].present?
      uploader = ProductImageUploader.new(resource)
      result = uploader.replace(params[:image], index)

      if result
        redirect_to admin_product_path(resource), notice: "Image #{index + 1} replaced in S3!"
      else
        redirect_to admin_product_path(resource), alert: "Failed to replace image."
      end
    else
      redirect_to admin_product_path(resource), alert: "No image selected."
    end
  end

  member_action :delete_all_images, method: :delete do
    uploader = ProductImageUploader.new(resource)
    uploader.delete_all

    redirect_to admin_product_path(resource), notice: "All images deleted!"
  end

  # Batch actions
  batch_action :publish do |ids|
    batch_action_collection.find(ids).each { |product| product.update!(published: true) }
    redirect_to collection_path, notice: "Products published!"
  end

  batch_action :unpublish do |ids|
    batch_action_collection.find(ids).each { |product| product.update!(published: false) }
    redirect_to collection_path, notice: "Products unpublished!"
  end

  # Member actions
  member_action :toggle_publish, method: :put do
    resource.update!(published: !resource.published)
    redirect_to admin_product_path(resource),
                notice: resource.published? ? "Product published!" : "Product unpublished!"
  end

  action_item :toggle_publish, only: :show do
    if resource.published?
      link_to "Unpublish", toggle_publish_admin_product_path(resource), method: :put,
              data: { confirm: "Unpublish this product?" }
    else
      link_to "Publish", toggle_publish_admin_product_path(resource), method: :put,
              data: { confirm: "Publish this product?" }
    end
  end

  # Sidebar
  sidebar "Quick Stats", only: :index do
    ul do
      li "Total: #{Product.count}"
      li "Published: #{Product.published.count}"
      li "Drafts: #{Product.unpublished.count}"
      li "Uncategorized: #{Product.uncategorized.count}"
    end
  end
end
