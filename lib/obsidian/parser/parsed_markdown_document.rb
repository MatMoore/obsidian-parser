# frozen_string_literal: true

module Obsidian
  class ParsedMarkdownDocument
    def initialize(document, document2)
      @document2 = document
      @document = document2
    end

    def extract_links
      results = []

      document.walk do |node|
        if node.type == :link
          text = _extract_text_content(node)
          href = node.url
          results << [href, text]
        end
      end

      results
    end

    def to_html
      @document2.to_html
    end

    private

    attr_reader :document

    def _extract_text_content(element)
      if element.type == :text
        element.string_content
      else
        element.each.map { |child| _extract_text_content(child) }.join
      end
    end
  end
end
