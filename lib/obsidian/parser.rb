# frozen_string_literal: true

require_relative "parser/version"
require_relative "parser/parsed_markdown_document"
require_relative "parser/markdown_parser"
require_relative "parser/page"
require_relative "parser/html_renderer"
require_relative "parser/content_type"

require "forwardable"

module Obsidian
  class Error < StandardError; end

  def self.build_slug(title, parent_slug)
    (parent_slug == "") ? title : "#{parent_slug}/#{title}"
  end

  class Parser
    attr_reader :index
    attr_reader :media_index

    def initialize(vault_directory)
      @index = Obsidian::Page.create_root
      @media_index = Obsidian::Page.create_root
      markdown_parser = MarkdownParser.new

      vault_directory.glob("**/*").each do |path|
        dirname, basename = path.relative_path_from(vault_directory).split

        next if basename == "."

        # Remove the path component "./" from the start of the dirname
        parent_slug = dirname.to_s.gsub(/\A\.\/?/, "")

        if basename.to_s.end_with?(".md")
          index_markdown(basename: basename, parent_slug: parent_slug, path: path, last_modified: path.mtime, markdown_parser: markdown_parser)
        else
          index_media(basename: basename, parent_slug: parent_slug, last_modified: path.mtime)
        end
      end

      # TODO: capture links between notes
    end

    def pages
      result = []
      index.walk_tree { |page| result << page }
      result
    end

    private

    def index_markdown(basename:, parent_slug:, last_modified:, path:, markdown_parser:)
      if basename.to_s == "index.md"
        slug = parent_slug.to_s.gsub(/\.md\z/, "")
      else
        title = basename.to_s.gsub(/\.md\z/, "")
        slug = Obsidian.build_slug(title, parent_slug)
      end

      @index.add_page(
        slug,
        last_modified: last_modified,
        content: lambda { path.read }
      )
    end

    def index_media(basename:, parent_slug:, last_modified:)
      @media_index.add_page(
        Obsidian.build_slug(basename.to_s, parent_slug),
        last_modified: last_modified,
        content_type: PretendEverythingIsAnImage.new
      )
    end
  end
end
