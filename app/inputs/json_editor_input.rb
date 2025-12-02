# frozen_string_literal: true

# Custom input for editing JSONB fields with dual interface:
# - JSON tab for developers
# - Form tab for non-technical users
class JsonEditorInput < Formtastic::Inputs::TextInput
  def to_html
    input_wrapping do
      json_value = object.send(method)
      json_string = json_value.is_a?(String) ? json_value : JSON.pretty_generate(json_value || {})

      # Generate unique ID for this editor
      editor_id = "json_editor_#{object.class.name.underscore}_#{method}_#{object.id || 'new'}"

      template.content_tag(:div, class: "json-editor-container", id: editor_id, data: { json_value: json_string }) do
        template.concat(render_tabs(editor_id))
        template.concat(render_json_view(editor_id, json_string))
        template.concat(render_form_view(editor_id, json_value))
        template.concat(render_hidden_field)
        template.concat(render_javascript(editor_id))
      end
    end
  end

  private

  def render_tabs(editor_id)
    template.content_tag(:div, class: "json-editor-tabs") do
      template.content_tag(:button, "📝 Form View", type: "button", class: "json-tab active", data: { target: "form", editor: editor_id }) +
      template.content_tag(:button, "{ } JSON View", type: "button", class: "json-tab", data: { target: "json", editor: editor_id })
    end
  end

  def render_json_view(editor_id, json_string)
    template.content_tag(:div, class: "json-view", id: "#{editor_id}_json", style: "display: none;") do
      template.content_tag(:textarea, json_string,
        class: "json-textarea",
        rows: 15,
        data: { editor: editor_id }
      ) +
      template.content_tag(:p, "Edit JSON directly. Changes sync automatically.", class: "json-hint")
    end
  end

  def render_form_view(editor_id, json_value)
    template.content_tag(:div, class: "form-view", id: "#{editor_id}_form") do
      if json_value.is_a?(Hash)
        render_hash_fields(json_value, "", editor_id)
      elsif json_value.is_a?(Array)
        template.content_tag(:p, "Array editing in form view coming soon. Use JSON view.", class: "json-hint")
      else
        template.content_tag(:p, "Simple value - use the text input above.", class: "json-hint")
      end
    end
  end

  def render_hash_fields(hash, prefix, editor_id, depth = 0)
    template.content_tag(:div, class: "json-form-fields depth-#{depth}") do
      hash.map do |key, value|
        field_path = prefix.empty? ? key : "#{prefix}.#{key}"
        render_field(key, value, field_path, editor_id, depth)
      end.join.html_safe
    end
  end

  def render_field(key, value, field_path, editor_id, depth)
    label_text = key.to_s.humanize.titleize

    template.content_tag(:div, class: "json-field") do
      case value
      when Hash
        # Nested object - render as fieldset
        template.content_tag(:fieldset, class: "json-nested") do
          template.content_tag(:legend, label_text) +
          render_hash_fields(value, field_path, editor_id, depth + 1)
        end
      when Array
        if value.all? { |v| v.is_a?(String) }
          # Array of strings - render as textarea with newlines
          template.content_tag(:label, label_text, for: "#{editor_id}_#{field_path}") +
          template.content_tag(:textarea, value.join("\n"),
            class: "json-field-input json-array-input",
            id: "#{editor_id}_#{field_path}",
            data: { path: field_path, type: "array", editor: editor_id },
            placeholder: "One item per line",
            rows: [value.length + 1, 3].max
          ) +
          template.content_tag(:span, "One item per line", class: "json-field-hint")
        else
          # Complex array - show as JSON
          template.content_tag(:label, label_text) +
          template.content_tag(:pre, JSON.pretty_generate(value), class: "json-preview")
        end
      when TrueClass, FalseClass
        template.content_tag(:label, class: "json-checkbox-label") do
          template.check_box_tag("#{editor_id}_#{field_path}", "1", value,
            class: "json-field-input json-checkbox",
            data: { path: field_path, type: "boolean", editor: editor_id }
          ) + " " + label_text
        end
      when Numeric
        template.content_tag(:label, label_text, for: "#{editor_id}_#{field_path}") +
        template.number_field_tag("#{editor_id}_#{field_path}", value,
          class: "json-field-input",
          data: { path: field_path, type: "number", editor: editor_id }
        )
      else
        # String or other - render as text input or textarea
        is_long = value.to_s.length > 100 || value.to_s.include?("\n")
        template.content_tag(:label, label_text, for: "#{editor_id}_#{field_path}") +
        if is_long
          template.content_tag(:textarea, value.to_s,
            class: "json-field-input",
            id: "#{editor_id}_#{field_path}",
            data: { path: field_path, type: "string", editor: editor_id },
            rows: 3
          )
        else
          template.text_field_tag("#{editor_id}_#{field_path}", value.to_s,
            class: "json-field-input",
            data: { path: field_path, type: "string", editor: editor_id }
          )
        end
      end
    end
  end

  def render_hidden_field
    template.hidden_field_tag(input_html_options[:name] || "#{object.class.name.underscore}[#{method}]", "",
      id: "#{input_html_options[:id] || "#{object.class.name.underscore}_#{method}"}_hidden",
      class: "json-hidden-field"
    )
  end

  def render_javascript(editor_id)
    template.content_tag(:script, <<~JS.html_safe)
      (function() {
        const container = document.getElementById('#{editor_id}');
        if (!container) return;
        
        const jsonTextarea = container.querySelector('.json-textarea');
        const hiddenField = container.querySelector('.json-hidden-field');
        const formView = document.getElementById('#{editor_id}_form');
        const jsonView = document.getElementById('#{editor_id}_json');
        const tabs = container.querySelectorAll('.json-tab');
        
        let currentJson = #{(object.send(method) || {}).to_json};
        
        // Initialize hidden field
        hiddenField.value = JSON.stringify(currentJson, null, 2);
        
        // Tab switching
        tabs.forEach(tab => {
          tab.addEventListener('click', function() {
            const target = this.dataset.target;
            tabs.forEach(t => t.classList.remove('active'));
            this.classList.add('active');
            
            if (target === 'json') {
              formView.style.display = 'none';
              jsonView.style.display = 'block';
              jsonTextarea.value = JSON.stringify(currentJson, null, 2);
            } else {
              jsonView.style.display = 'none';
              formView.style.display = 'block';
              // Sync JSON changes to form
              try {
                currentJson = JSON.parse(jsonTextarea.value);
                syncJsonToForm();
              } catch(e) {
                alert('Invalid JSON. Please fix before switching to Form View.');
                tabs.forEach(t => t.classList.remove('active'));
                container.querySelector('[data-target="json"]').classList.add('active');
                jsonView.style.display = 'block';
                formView.style.display = 'none';
              }
            }
          });
        });
        
        // JSON textarea changes
        jsonTextarea.addEventListener('input', function() {
          try {
            currentJson = JSON.parse(this.value);
            hiddenField.value = this.value;
            this.classList.remove('json-error');
          } catch(e) {
            this.classList.add('json-error');
          }
        });
        
        // Form field changes
        container.querySelectorAll('.json-field-input').forEach(input => {
          input.addEventListener('input', function() {
            updateJsonFromForm(this);
          });
          input.addEventListener('change', function() {
            updateJsonFromForm(this);
          });
        });
        
        function updateJsonFromForm(input) {
          const path = input.dataset.path;
          const type = input.dataset.type;
          let value;
          
          if (type === 'boolean') {
            value = input.checked;
          } else if (type === 'number') {
            value = parseFloat(input.value) || 0;
          } else if (type === 'array') {
            value = input.value.split('\\n').filter(s => s.trim() !== '');
          } else {
            value = input.value;
          }
          
          setNestedValue(currentJson, path, value);
          hiddenField.value = JSON.stringify(currentJson, null, 2);
        }
        
        function setNestedValue(obj, path, value) {
          const keys = path.split('.');
          let current = obj;
          for (let i = 0; i < keys.length - 1; i++) {
            if (!(keys[i] in current)) {
              current[keys[i]] = {};
            }
            current = current[keys[i]];
          }
          current[keys[keys.length - 1]] = value;
        }
        
        function getNestedValue(obj, path) {
          const keys = path.split('.');
          let current = obj;
          for (const key of keys) {
            if (current === undefined || current === null) return undefined;
            current = current[key];
          }
          return current;
        }
        
        function syncJsonToForm() {
          container.querySelectorAll('.json-field-input').forEach(input => {
            const path = input.dataset.path;
            const type = input.dataset.type;
            const value = getNestedValue(currentJson, path);
            
            if (type === 'boolean') {
              input.checked = !!value;
            } else if (type === 'array') {
              input.value = Array.isArray(value) ? value.join('\\n') : '';
            } else {
              input.value = value !== undefined ? value : '';
            }
          });
        }
      })();
    JS
  end
end
