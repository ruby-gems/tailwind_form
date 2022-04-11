require "tailwind_form/version"
require "tailwind_form/engine"

require "tailwind_form/association"
require "tailwind_form/form_errors"
require "tailwind_form/form_validator"
require "tailwind_form/form_wrap"
require "tailwind_form/form_builder"

module TailwindForm
  mattr_accessor :field_error_proc

  @@field_error_proc = proc do |html_tag, instance|
    is_label_tag = html_tag =~ /^<label/
    class_attr_index = html_tag.index 'class="'

    if class_attr_index && !is_label_tag
      html_tag.insert(class_attr_index + 7, "is-invalid ")
    elsif !class_attr_index && !is_label_tag
      html_tag.insert(html_tag.index(">"), " class=is-invalid")
    else
      html_tag.html_safe
    end
    html_tag.html_safe
  end
end
