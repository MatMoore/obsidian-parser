# frozen_string_literal: true

module Obsidian
  class MarkdownContent
    def initialize(path, root, renderer:)
      @path = path
      @root = root
      @renderer = renderer
    end

    def generate_html
      markdown = @path.read
      Obsidian::ObsidianFlavoredMarkdown.parse(markdown, root: @root, renderer: @renderer).to_html
    end
  end
end
