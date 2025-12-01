ActiveAdmin.register SiteSetting do
  menu priority: 5, label: "Site Settings", parent: "Configuration"

  # Disable destroy - site settings should not be deleted
  actions :all, except: [ :destroy, :new ]

  permit_params :key, :value

  # Filters
  filter :key, as: :select, collection: -> { SiteSetting.all.pluck(:key).sort }
  filter :updated_at

  # Index page - show as key-value pairs
  index do
    column :key do |setting|
      code setting.key
    end
    column :value do |setting|
      value = setting.value
      case value
      when Hash, Array
        pre JSON.pretty_generate(value), style: "max-height: 150px; overflow: auto; font-size: 11px;"
      when TrueClass, FalseClass
        status_tag value ? "Yes" : "No", class: value ? "yes" : "no"
      else
        value.to_s.truncate(100)
      end
    end
    column :description do |setting|
      default = SiteSetting::DEFAULTS[setting.key]
      default&.dig("description") || "-"
    end
    column :updated_at
    actions
  end

  # Show page
  show do
    attributes_table do
      row :key do |setting|
        code setting.key
      end
      row :description do |setting|
        default = SiteSetting::DEFAULTS[setting.key]
        default&.dig("description") || "-"
      end
      row :value do |setting|
        value = setting.value
        case value
        when Hash, Array
          pre JSON.pretty_generate(value), style: "max-width: 100%; overflow: auto;"
        else
          value.to_s
        end
      end
      row :default_value do |setting|
        default = SiteSetting::DEFAULTS[setting.key]&.dig("value")
        if default
          case default
          when Hash, Array
            pre JSON.pretty_generate(default), style: "max-width: 100%; overflow: auto; background: #f5f5f5;"
          else
            default.to_s
          end
        else
          "-"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # Form
  form do |f|
    default = SiteSetting::DEFAULTS[f.object.key]

    f.inputs "Setting Details" do
      f.input :key, input_html: { readonly: true, disabled: true },
              hint: "Key cannot be changed"

      if default
        para strong("Description: "), default["description"]
      end
    end

    f.inputs "Value" do
      # Determine value type from defaults or current value
      value = f.object.value
      is_json = value.is_a?(Hash) || value.is_a?(Array)

      if is_json
        f.input :value, as: :text, input_html: {
          rows: 15,
          value: JSON.pretty_generate(value),
          class: "json-editor"
        }, hint: "Edit JSON carefully. Invalid JSON will cause errors."
      elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
        f.input :value, as: :boolean
      else
        f.input :value, as: :string
      end
    end

    f.actions
  end

  # Custom controller to handle JSON parsing
  controller do
    def update
      @site_setting = SiteSetting.find(params[:id])

      # Parse JSON if the value looks like JSON
      value_param = params[:site_setting][:value]

      if value_param.is_a?(String) && (value_param.strip.start_with?("{") || value_param.strip.start_with?("["))
        begin
          parsed_value = JSON.parse(value_param)
          @site_setting.value = parsed_value
        rescue JSON::ParserError => e
          @site_setting.errors.add(:value, "Invalid JSON: #{e.message}")
          render :edit, status: :unprocessable_entity
          return
        end
      else
        # Handle boolean strings
        if value_param == "1" || value_param == "true"
          @site_setting.value = true
        elsif value_param == "0" || value_param == "false"
          @site_setting.value = false
        else
          @site_setting.value = value_param
        end
      end

      if @site_setting.save
        redirect_to admin_site_setting_path(@site_setting), notice: "Setting updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  # Member action to reset to default
  member_action :reset_to_default, method: :put do
    default = SiteSetting::DEFAULTS[resource.key]
    if default
      resource.update!(value: default["value"])
      redirect_to admin_site_setting_path(resource), notice: "Setting reset to default value."
    else
      redirect_to admin_site_setting_path(resource), alert: "No default value found for this setting."
    end
  end

  action_item :reset, only: :show do
    if SiteSetting::DEFAULTS[resource.key]
      link_to "Reset to Default", reset_to_default_admin_site_setting_path(resource),
              method: :put,
              data: { confirm: "Reset this setting to its default value?" }
    end
  end

  # Collection action to seed all defaults
  collection_action :seed_defaults, method: :post do
    SiteSetting.seed_defaults!
    redirect_to admin_site_settings_path, notice: "All default settings have been seeded."
  end

  action_item :seed_defaults, only: :index do
    link_to "Seed All Defaults", seed_defaults_admin_site_settings_path,
            method: :post,
            data: { confirm: "This will create any missing default settings. Existing settings will not be overwritten. Continue?" }
  end

  # Sidebar with categories
  sidebar "Settings Groups", only: :index do
    groups = {
      "Site Information" => %w[site_info contact_info],
      "Homepage" => %w[hero_section featured_categories featured_products carousel_images],
      "Layout" => %w[footer_content social_links],
      "SEO" => %w[meta_defaults],
      "Other" => []
    }

    # Find ungrouped settings
    all_grouped = groups.values.flatten
    SiteSetting.all.each do |setting|
      groups["Other"] << setting.key unless all_grouped.include?(setting.key)
    end

    groups.each do |group_name, keys|
      next if keys.empty?

      h4 group_name, style: "margin-top: 10px;"
      ul do
        keys.each do |key|
          setting = SiteSetting.find_by(key: key)
          if setting
            li link_to(key.humanize.titleize, admin_site_setting_path(setting))
          end
        end
      end
    end
  end
end
