# frozen_string_literal: true

module TailwindForm
  module FormErrors
    def errors_on_attribute(attribute_name)
      object.errors[attribute_name] || []
    end

    def errors(attribute_name)
      (errors_on_attribute(attribute_name) + errors_on_association(attribute_name)).compact.uniq
    end

    def errors_on_association(association)
      reflection = find_association_reflection(association)
      reflection ? object.errors[reflection.name] : []
    end
  end
end
