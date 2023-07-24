# frozen_string_literal: true

module Obsidian
  class MarkdownConverter
    def initialize(document)
      @document = document
    end

    def extract_links
      _extract_links(document.root)
    end

    def to_html
      document.to_html
    end

    private

    attr_reader :document

    def _extract_links(element)
      if element.type == :a
        [[element.attr["href"], _extract_text_content(element)]]
      elsif !element.children.empty?
        element.children.flat_map { |child| _extract_links(child) }
      else
        []
      end
    end

    def _extract_text_content(element)
      if element.type == :text
        element.value
      elsif !element.children.empty?
        element.children.map { |child| _extract_text_content(child) }.join
      else
        ""
      end
    end
  end
end
