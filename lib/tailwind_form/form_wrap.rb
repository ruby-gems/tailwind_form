# frozen_string_literal: true

module TailwindForm
  module FormWrap
    def wrapping(type, inner, tag: "div", wrap: {input: "form-inputs > form-item"})
      if wrap[type].present?
        css_ary = wrap[type].split(" > ")
        css_ary.reverse_each.with_index do |css, index|
          inner = if index == 0
            @template.content_tag(tag, inner, class: css)
          else
            @template.content_tag("div", inner, class: css)
          end
        end
      end

      inner
    end

    def group(&block)
      @template.content_tag :div, class: "form-group" do
        label = @template.content_tag :div, class: "form-label" do
        end
        @template.concat label
        inputs = @template.content_tag :div, class: "form-inputs" do
          @template.content_tag :div, class: "form-item" do
            yield block
          end
        end
        @template.concat inputs
      end
    end
  end
end
