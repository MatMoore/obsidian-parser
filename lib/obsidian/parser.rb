# frozen_string_literal: true

require_relative "parser/version"
require_relative "parser/parsed_markdown_document"
require_relative "parser/obsidian_flavored_markdown"
require_relative "parser/page"

require "forwardable"

module Obsidian
  class Error < StandardError; end

  def self.build_slug(title, parent_slug)
    (parent_slug == "") ? title : "#{parent_slug}/#{title}"
  end

  class MarkdownContent
    def initialize(path)
      @path = path
    end

    def generate_html
      markdown = @path.read
      Obsidian::ObsidianFlavoredMarkdown.parse(markdown).to_html
    end
  end

  class Parser
    attr_reader :index

    def initialize(vault_directory)
      @index = Obsidian::Page.create_root

      vault_directory.glob("**/*.md").each do |path|
        dirname, basename = path.relative_path_from(vault_directory).split

        next if basename == "."

        # TODO: handle index.md files
        if basename != "index.md"
          title = basename.to_s.gsub(/\.md\z/, "")
          parent_slug = dirname.to_s.gsub(/\A\.\/?/, "")
          slug = Obsidian.build_slug(title, parent_slug)
          content = MarkdownContent.new(path)

          @index.add_page(
            slug,
            last_modified: path.mtime,
            content: content
          )
        end
      end

      # TODO: capture links between notes
    end

    def pages
      result = []
      index.walk_tree { |page| result << page }
      result
    end
  end
end
