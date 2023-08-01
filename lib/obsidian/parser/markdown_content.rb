# frozen_string_literal: true

module Obsidian
  class MarkdownContent
    def initialize(path, root)
      @path = path
      @root = root
    end

    def generate_html
      markdown = @path.read
      Obsidian::ObsidianFlavoredMarkdown.parse(markdown, root: @root).to_html
    end
  end
end
