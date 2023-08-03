# frozen_string_literal: true

require_relative "parser/version"
require_relative "parser/parsed_markdown_document"
require_relative "parser/markdown_parser"
require_relative "parser/page"
require_relative "parser/markdown_document"
require_relative "parser/html_renderer"

require "forwardable"

module Obsidian
  class Error < StandardError; end

  def self.build_slug(title, parent_slug)
    (parent_slug == "") ? title : "#{parent_slug}/#{title}"
  end

  class Parser
    attr_reader :index

    def initialize(vault_directory)
      @index = Obsidian::Page.create_root
      markdown_parser = MarkdownParser.new

      vault_directory.glob("**/*.md").each do |path|
        dirname, basename = path.relative_path_from(vault_directory).split

        next if basename == "."

        # Remove the path component "." from the start of the dirname
        parent_slug = dirname.to_s.gsub(/\A\.\/?/, "")

        if basename.to_s == "index.md"
          slug = parent_slug.to_s.gsub(/\.md\z/, "")
        else
          title = basename.to_s.gsub(/\.md\z/, "")
          slug = Obsidian.build_slug(title, parent_slug)
        end

        @index.add_page(
          slug,
          last_modified: path.mtime,
          content: MarkdownDocument.new(path, @index, markdown_parser: markdown_parser)
        )
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
