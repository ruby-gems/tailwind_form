# frozen_string_literal: true

module TailwindForm
  module FormValidator
    def required_attribute?(attribute)
      return false unless object && attribute
      target = object.to_model.instance_of?(Class) ? object : object.to_model.class

      target_validators = if target.respond_to? :validators_on
        target.validators_on(attribute).map(&:class)
      else
        []
      end
      # binding.pry if attribute.to_sym === :admin_user_id
      presence_validator?(target_validators)
    end

    def reflection_validators(attribute)
      find_association_reflection(attribute)
    end

    def presence_validator?(target_validators)
      has_presence_validator = target_validators.include?(
        ActiveModel::Validations::PresenceValidator
      )

      if defined? ActiveRecord::Validations::PresenceValidator
        has_presence_validator |= target_validators.include?(
          ActiveRecord::Validations::PresenceValidator
        )
      end

      has_presence_validator
    end
  end
end
