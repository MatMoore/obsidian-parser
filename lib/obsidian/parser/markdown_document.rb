# frozen_string_literal: true

module Obsidian
  class MarkdownDocument
    def initialize(path, root, markdown_parser:)
      @path = path
      @root = root
      @markdown_parser = markdown_parser
    end

    def generate_html
      markdown = @path.read
      @markdown_parser.parse(markdown, root: @root).to_html
    end
  end
end
