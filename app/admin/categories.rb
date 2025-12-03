ActiveAdmin.register Category do
  menu priority: 3, label: "Categories"

  permit_params :name, :slug, :description, :icon, :position, :parent_id, :icon_image

  # Filters
  filter :name
  filter :slug
  filter :parent, as: :select, collection: -> { Category.roots.ordered }
  filter :created_at

  # Scope tabs
  scope :all
  scope :roots, default: true

  # Index page - tree view
  index do
    selectable_column
    id_column
    column :icon
    column :name do |category|
      if category.parent.present?
        "└── #{category.name}"
      else
        strong(category.name)
      end
    end
    column :slug
    column :parent
    column :products do |category|
      link_to category.products.count, admin_products_path(q: { category_id_eq: category.id })
    end
    column :position
    column :created_at
    actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :icon
      row :icon_image do |category|
        category.icon_image.attached? ? image_tag(category.icon_image, width: 50) : "-"
      end
      row :description
      row :parent
      row :full_path
      row :depth
      row :position
      row :children do |category|
        if category.children.any?
          ul do
            category.children.ordered.each do |child|
              li { link_to child.name, admin_category_path(child) }
            end
          end
        else
          "-"
        end
      end
      row :products_count do |category|
        link_to category.products.count, admin_products_path(q: { category_id_eq: category.id })
      end
      row :all_products_count do |category|
        category.all_products.count
      end
      row :created_at
      row :updated_at
    end
  end

  # Form
  form do |f|
    f.inputs "Category Details" do
      f.input :name
      f.input :slug, hint: "Auto-generated from name if left blank"
      f.input :icon, hint: "Emoji icon (e.g., 🔧)"
      f.input :icon_image, as: :file, hint: "Optional image icon"
      f.input :description
      f.input :parent, as: :select,
              collection: Category.roots.ordered.where.not(id: f.object.id),
              include_blank: "-- No Parent (Root Category) --"
      f.input :position
    end
    f.actions
  end

  # Sidebar with children
  sidebar "Subcategories", only: :show do
    if resource.children.any?
      table_for resource.children.ordered do
        column :icon
        column :name do |child|
          link_to child.name, admin_category_path(child)
        end
        column :products do |child|
          child.products.count
        end
      end
    else
      para "No subcategories"
    end
  end

  # Sidebar with products
  sidebar "Recent Products", only: :show do
    table_for resource.products.limit(5) do
      column :name do |product|
        link_to product.name.truncate(30), admin_product_path(product)
      end
      column :price do |product|
        number_to_currency(product.price, unit: "₹")
      end
    end
    if resource.products.count > 5
      para link_to "View all #{resource.products.count} products",
                   admin_products_path(q: { category_id_eq: resource.id })
    end
  end
end
