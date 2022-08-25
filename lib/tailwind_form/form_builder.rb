# frozen_string_literal: true

module TailwindForm
  class FormBuilder < ActionView::Helpers::FormBuilder
    include TailwindForm::Association
    include TailwindForm::FormValidator
    include TailwindForm::FormErrors
    include TailwindForm::FormWrap

    def label(method, text = nil, options = {}, &block)
      classes = [options[:class]]
      reflection = options.delete(:reflection)
      method = reflection.name if reflection
      case options.delete(:required)
      when true
        classes << "required"
      when nil, :default
        classes << "required" if required_attribute?(method)
      end

      options = options.merge(class: classes.flatten.compact.size > 0 ? classes.flatten.compact : nil)
      super
    end

    # Renders a form field with label wrapped in an appropriate +<div>+, with another +<div>+ for errors if necessary.
    #
    # @param field_name [String, Symbol] Name of the field to render
    # @param label [String, Symbol] Override text for the +<label>+ element
    # @param type [Symbol] Override type of field to render.
    #   Known values are +:date+, +:email+, +:password+, +:select+, +:textarea+, and +:time_zone+. Anything else is rendered as a text field.
    # @param values [Array] Name-value pairs for +<option>+ elements. Only meaningful with +type:+ +:select+.
    # @param field [Hash] Options to pass through to the underlying Rails form helper. For +type:+ +:time_zone+, +:priority_zones+ is also understood.
    # @return [SafeBuffer] The rendered HTML
    def input(field_name, label: nil, label_html: {}, as: nil, values: nil, input_html: {})
      raise ArgumentError, ":values is only meaningful with type: :select" if values && as != :select
      # puts field_name
      # binding.pry if field_name.to_s == "member_id"
      reflection = input_html.delete(:reflection)
      append = input_html.delete(:append)
      prepend = input_html.delete(:prepend)

      hint = input_html.delete(:hint)

      error_field_name = reflection ? reflection.name : field_name

      if errors[error_field_name]&.any?
        input_html[:error] = true
      end

      nowrap = input_html.delete(:nowrap)

      if nowrap
        return input_for(field_name, as, input_html, values: values) + errors_for(error_field_name)
      end

      @template.content_tag(:div, class: classes_for(field_name)) do
        # [
        # label(field_name, label, class: 'form-label') + @template.content_tag(:div, class: 'form-inputs') do
        #   input_for(field_name, as, field, values: values) + errors_for(field_name)
        # end
        # @template.content_tag :div, class: 'form-inputs' do
        #   input_for(field_name, as, field, values: values)
        # end
        # ].compact.join("\n").html_safe
        # err = errors_for(field_name)
        # if reflection
        #  err = errors_for(reflection.name)
        # end
        # label_options = required_attribute?() if required_attribute?(method)
        label_options = {reflection: reflection}.merge(label_html)
        # input_label = label != false ? label(field_name, label, label_options) : ""

        label_dev = label != false ? @template.content_tag(:div, class: "form-label") do
          label(field_name, label, label_options)
        end : ""

        inputs = input_for(field_name, as, input_html, values: values)
        if append
          inputs += @template.content_tag(:div, append, class: "form-input-text ")
        end
        if prepend
          inputs = @template.content_tag(:div, prepend, class: "form-input-text ") + inputs
        end

        inputs += errors_for(error_field_name)
        if hint && errors[field_name].blank?
          inputs += @template.content_tag(:div, hint, class: "form-hint")
        end

        # style
        # type = as ? as : infer_type(field_name)
        type = as || (@object.nil? ? :text_field : infer_type(field_name))
        (label_dev + wrapping(type, inputs)).html_safe
      end
    end

    # private
    def classes_for(field_name)
      [field_name, error_class(field_name), "form-group"]
    end

    def error_class(field_name)
      errors[field_name].present? ? :error : nil
    end

    # Renders a +<span>+ with errors if there are any for the specified field, or returns +nil+ if not.
    #
    # @param field_name [String, Symbol] Name of the field to check for errors
    # @return [SafeBuffer, nil] The rendered HTML or nil
    def errors_for(field_name)
      error_messages = errors[field_name]

      if error_messages.present?
        @template.content_tag(:div, class: "invalid-feedback") do
          # error_messages.join(@template.tag :br).html_safe
          error_messages.first
        end
      end
    end

    def errors
      @errors ||= @object.present? ? @object.errors : {}
    end

    def input_for(field_name, type = :text_field, field_options = {}, values: nil)
      type ||= @object.nil? ? :text_field : infer_type(field_name)
      classes = field_options.delete(:class) || "form-input"
      is_valid = field_options.delete(:error)

      if type != :select
        classes += " is-invalid" if is_valid
        field_options[:class] ||= classes
      end

      # binding.pry
      case type
      when :select

        html_options ||= field_options.delete(:html) || {}
        html_options[:class] ||= "form-input"

        if is_valid
          html_options[:class] += " is-invalid"
          # select(method, choices = nil, options = {}, html_options = {}, &block)
        end
        select(field_name, values, field_options, html_options)
      when :time_zone
        priority_zones = field_options.delete(:priority_zones)
        time_zone_select(field_name, priority_zones, field_options)
      when :boolean
        check_box(field_name, field_options.merge(class: "form-checkbox"))
      when :rich_text
        rich_text_area(field_name, field_options.merge(class: "form-input form-rich-text"))
      else
        method_mappings = {
          date: :date_field,
          email: :email_field,
          numeric: :number_field,
          password: :password_field,
          textarea: :text_area,
          file: :file_field
        }

        field_method = method_mappings[type] || :text_field

        send(field_method, field_name, field_options)
      end
    end

    # Infers the type of field to render based on the field name.
    #
    # @param [String, Symbol] the name of the field
    # @return [Symbol] the inferred type
    def infer_type(field_name)
      case field_name
      when :email, :time_zone
        field_name
      when %r{(\b|_)password(\b|_)}
        :password
      else
        # type_mappings = {text: :textarea}
        db_type = @object.column_for_attribute(field_name).type
        case db_type
        when :text
          :textarea
        when :decimal, :integer, :float
          :numeric
        when :boolean
          :boolean
        else
          db_type
        end
      end
    end
  end
end
