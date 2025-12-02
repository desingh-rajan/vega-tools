class PagesController < ApplicationController
  def home
    # Load all landing page settings with bulletproof defaults
    # SiteSetting.value_for ALWAYS returns a value (DB or YAML default)
    @site_info = SiteSetting.value_for("site_info")
    @contact_info = SiteSetting.value_for("contact_info")
    @hero_section = SiteSetting.value_for("hero_section")
    @stats_section = SiteSetting.value_for("stats_section")
    @about_section = SiteSetting.value_for("about_section")
    @social_links = SiteSetting.value_for("social_links")
    @theme_config = SiteSetting.value_for("theme_config")
  end
end
