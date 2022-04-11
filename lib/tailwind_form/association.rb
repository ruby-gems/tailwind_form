module TailwindForm
  module Association
    def association(association, options = {}, &block)
      options = options.dup
      if block
        return fields_for(
          *[
            association,
            options.delete(:collection),
            options
          ].compact,
          &block
        )
      end

      raise ArgumentError, "Association cannot be used in forms not associated with an object" unless object
      reflection = find_association_reflection(association)
      raise "Association #{association.inspect} not found" unless reflection

      # options[:type] ||= :select
      type = options.delete(:as) || :select
      # options[:values] ||= fetch_association_collection(reflection, options)
      values = options.delete(:collection) || fetch_association_collection(reflection, options).map { |a| [a.to_s, a.id] }

      attribute = build_association_attribute(reflection, association, options)
      # errs = errors_on_association(association)
      input_html = options.merge(reflection: reflection)
      input(attribute, as: type, values: values, input_html: input_html)
      # input(attribute, type: type, values: values, field: options)
    end

    def find_association_reflection(association)
      if @object.class.respond_to?(:reflect_on_association)
        @object.class.reflect_on_association(association)
      end
    end

    private

    def fetch_association_collection(reflection, options)
      options.fetch(:collection) do
        relation = reflection.klass.all

        if reflection.respond_to?(:scope) && reflection.scope
          relation = if reflection.scope.parameters.any?
            reflection.klass.instance_exec(object, &reflection.scope)
          else
            reflection.klass.instance_exec(&reflection.scope)
          end
        else
          order = reflection.options[:order]
          conditions = reflection.options[:conditions]
          conditions = object.instance_exec(&conditions) if conditions.respond_to?(:call)

          relation = relation.where(conditions) if relation.respond_to?(:where)
          relation = relation.order(order) if relation.respond_to?(:order)
        end
        relation
      end
    end

    def build_association_attribute(reflection, association, options)
      case reflection.macro
      when :belongs_to
        (reflection.respond_to?(:options) && reflection.options[:foreign_key]) || :"#{reflection.name}_id"
      when :has_one
        raise ArgumentError, ":has_one associations are not supported by f.association"
      else
        if options[:as] == :select || options[:as] == :grouped_select || reflection.macro == :has_many || reflection.macro == :has_and_belongs_to_many
          html_options = options[:html] ||= {}
          html_options[:multiple] = true unless html_options.key?(:multiple)
        end

        # Force the association to be preloaded for performance.
        if options[:preload] != false && object.respond_to?(association)
          target = object.send(association)
          target.to_a if target.respond_to?(:to_a)
        end
        :"#{reflection.name.to_s.singularize}_ids"
      end
    end
  end
end
