# frozen_string_literal: true

module JsonDisplayHelper
  def render_json_preview(value, max_height: 150)
    case value
    when Hash, Array
      content_tag(:div, class: "json-display", style: "max-height: #{max_height}px;") do
        content_tag(:pre, JSON.pretty_generate(value), style: "margin: 0; font-size: 11px;")
      end
    when TrueClass, FalseClass
      status_tag value ? "Yes" : "No", class: value ? "yes" : "no"
    else
      value.to_s.truncate(100)
    end
  end

  def render_json_display(value, muted: false)
    case value
    when Hash
      content_tag(:div, class: "json-key-value-display #{'muted' if muted}") do
        safe_join(value.map { |k, v| render_kv_row(k, v) })
      end
    when Array
      content_tag(:div, class: "json-display") do
        content_tag(:pre, JSON.pretty_generate(value), style: "margin: 0;")
      end
    else
      value.to_s
    end
  end

  def render_kv_row(key, value, depth: 0)
    content_tag(:div, class: "json-kv-row", style: depth > 0 ? "margin-left: #{depth * 20}px;" : "") do
      key_html = content_tag(:span, key.to_s.humanize.titleize, class: "json-kv-key")

      value_html = case value
      when Hash
        content_tag(:div, class: "json-kv-nested") do
          safe_join(value.map { |k, v| render_kv_row(k, v, depth: depth + 1) })
        end
      when Array
        if value.all? { |v| v.is_a?(String) }
          content_tag(:span, value.join(", "), class: "json-kv-value")
        else
          content_tag(:pre, JSON.pretty_generate(value), class: "json-preview", style: "margin: 0;")
        end
      when TrueClass, FalseClass
        status_tag value ? "Yes" : "No", class: value ? "yes" : "no"
      else
        content_tag(:span, value.to_s, class: "json-kv-value")
      end

      key_html + value_html
    end
  end
end
