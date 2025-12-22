ActiveAdmin.register SiteSetting do
  menu priority: 5, label: "Site Settings", parent: "Configuration"

  # Disable destroy - site settings should not be deleted
  actions :all, except: [ :destroy, :new ]

  permit_params :key, :value

  # Filters
  filter :key, as: :select, collection: -> { SiteSetting.all.pluck(:key).sort }
  filter :updated_at

  # Index page - show as key-value pairs with pretty display
  index do
    column :key do |setting|
      code setting.key
    end
    column :value do |setting|
      value = setting.value
      case value
      when Hash, Array
        div class: "json-display", style: "max-height: 150px;" do
          pre JSON.pretty_generate(value), style: "margin: 0; font-size: 11px;"
        end
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

  # Show page with pretty JSON display
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
        if value.is_a?(Hash)
          div class: "json-key-value-display" do
            value.each do |k, v|
              div class: "json-kv-row" do
                span k.to_s.humanize.titleize, class: "json-kv-key"
                if v.is_a?(Hash)
                  div class: "json-kv-nested" do
                    v.each do |k2, v2|
                      div class: "json-kv-row", style: "margin-left: 20px;" do
                        span k2.to_s.humanize.titleize, class: "json-kv-key"
                        span v2.to_s, class: "json-kv-value"
                      end
                    end
                  end
                elsif v.is_a?(Array)
                  span v.join(", "), class: "json-kv-value"
                else
                  span v.to_s, class: "json-kv-value"
                end
              end
            end
          end
        elsif value.is_a?(Array)
          pre JSON.pretty_generate(value)
        else
          value.to_s
        end
      end
      row :default_value do |setting|
        default = SiteSetting::DEFAULTS[setting.key]&.dig("value")
        if default
          pre JSON.pretty_generate(default), style: "background: #f5f5f5; padding: 10px; border-radius: 4px;"
        else
          "-"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # Form with dual JSON/Form interface
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
      value = f.object.value
      is_json = value.is_a?(Hash) || value.is_a?(Array)

      if is_json
        f.input :value, as: :json_editor
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
      button_to "Reset to Default", reset_to_default_admin_site_setting_path(resource),
                method: :put,
                data: { confirm: "Reset this setting to its default value?", turbo: false },
                form: { style: "display: inline-block;" },
                class: "button"
    end
  end

  # Collection action to seed all defaults
  collection_action :seed_defaults, method: :post do
    SiteSetting.seed_defaults!
    redirect_to admin_site_settings_path, notice: "All default settings have been seeded."
  end

  action_item :seed_defaults, only: :index do
    button_to "Seed All Defaults", seed_defaults_admin_site_settings_path,
              method: :post,
              data: { confirm: "This will create any missing default settings. Existing settings will not be overwritten. Continue?", turbo: false },
              form: { style: "display: inline-block;" },
              class: "button"
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

    # Preload all settings for all keys in all groups
    all_keys = groups.values.flatten.uniq
    settings_by_key = SiteSetting.where(key: all_keys).index_by(&:key)

    groups.each do |group_name, keys|
      next if keys.empty?

      h4 group_name, style: "margin-top: 10px;"
      ul do
        keys.each do |key|
          setting = settings_by_key[key]
          if setting
            li link_to(key.humanize.titleize, admin_site_setting_path(setting))
          end
        end
      end
    end
  end
end
