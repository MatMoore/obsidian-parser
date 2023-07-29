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

  class Note
    extend Forwardable

    def_delegators :@page, :title, :slug, :last_modified, :content

    def initialize(page)
      @page = page
    end

    def inspect
      "Note(title: #{@page.title.inspect}, slug: #{@page.slug.inspect})"
    end

    def parent
      @page.parent.is_index? ? Index.new(@page.parent) : Note.new(@page.parent)
    end
  end

  class Index
    extend Forwardable

    def_delegators :@page, :title, :slug, :last_modified, :content

    def initialize(page)
      @page = page
    end

    def add_directory(title)
      new_slug = Obsidian.build_slug(title, slug)
      directory = @page.get_or_create_child(title: title, slug: new_slug)
      Index.new(directory)
    end

    def add_note(title, parent_slug, last_modified, content: nil)
      slug = Obsidian.build_slug(title, parent_slug)
      note = @page.add_page(slug, last_modified: last_modified, content: content)
      Note.new(note)
    end

    def inspect
      "Index(title: #{@page.title.inspect}, slug: #{@page.slug.inspect})"
    end

    def directories
      @page.children.filter(&:is_index?).map { |d| Index.new(d) }
    end

    def notes
      @page.children.reject(&:is_index?).map { |n| Note.new(n) }
    end
  end

  class Parser
    attr_reader :index

    def initialize(vault_directory)
      @index = Index.new(Obsidian::Page.create_root)

      vault_directory.glob("**/*.md").each do |path|
        dirname, basename = path.relative_path_from(vault_directory).split

        next if basename == "."

        # TODO: handle index.md files
        if basename != "index.md"
          title = basename.to_s.gsub(/\.md\z/, "")
          parent_slug = dirname.to_s.gsub(/\A\.\/?/, "")
          content = MarkdownContent.new(path)
          @index.add_note(title, parent_slug, path.mtime, content: content)
        end
      end

      # TODO: capture links between notes
    end

    def notes
      table_of_contents.map(&:first)
    end

    def walk_tree(index, level = 0, &block)
      index.directories.sort_by(&:title).each do |note|
        block.call(note, level)
        walk_tree(note, level + 1, &block)
      end

      index.notes.sort_by(&:title).each do |note|
        block.call(note, level)
      end
    end

    def table_of_contents
      result = []
      walk_tree(index) { |note, level| result << [note, level] }
      result
    end
  end
end
