class SiteSettingsController < ApplicationController
  # GET /site_settings or /site_settings.json
  def index
    @settings = SiteSetting.public_settings

    respond_to do |format|
      format.json { render json: settings_hash(@settings) }
    end
  end

  # GET /site_settings/:key or /site_settings/:key.json
  def show
    setting = SiteSetting.find_by(key: params[:key], is_public: true)

    respond_to do |format|
      format.json do
        if setting
          render json: { key: setting.key, value: setting.value }
        else
          # Return default from YAML if exists
          default_value = SiteSetting.default_value_for(params[:key])
          if default_value.present?
            render json: { key: params[:key], value: default_value }
          else
            render json: { error: "Setting not found" }, status: :not_found
          end
        end
      end
    end
  end

  # GET /site_settings/homepage.json
  # Returns all settings needed for homepage in one request
  def homepage
    keys = %w[site_info contact_info hero_section stats_section about_section social_links theme_config products_section featured_categories]

    settings = keys.each_with_object({}) do |key, hash|
      hash[key] = SiteSetting.value_for(key)
    end

    respond_to do |format|
      format.json { render json: settings }
    end
  end

  private

  def settings_hash(settings)
    settings.each_with_object({}) do |setting, hash|
      hash[setting.key] = setting.value
    end
  end
end
