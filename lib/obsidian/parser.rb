# frozen_string_literal: true

require_relative "parser/version"
require_relative "parser/markdown_converter"
require_relative "parser/obsidian_flavored_markdown"

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
    def initialize(title, slug, last_modified, content: nil)
      # TODO: check frontmatter for titles as well
      @title = title
      @slug = slug
      @last_modified = last_modified
      @content = content
    end

    def inspect
      "Note(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    attr_reader :title
    attr_reader :slug
    attr_reader :last_modified
    attr_reader :content
  end

  class Index
    def initialize(title = "", slug = "", content: nil)
      @title = title
      @slug = slug
      @notes = []
      @directories = {}
      @content = content
    end

    def add_directory(title)
      new_slug = Obsidian.build_slug(title, slug)
      @directories[title] ||= Index.new(title, new_slug)
    end

    def add_note(title, parent_slug, last_modified, content: nil)
      slug = Obsidian.build_slug(title, parent_slug)
      directory = nested_directory(parent_slug.split("/"))
      note = Note.new(title, slug, last_modified, content: content)

      directory.notes << note
    end

    def inspect
      "Index(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    def directories
      @directories.values
    end

    attr_reader :notes
    attr_reader :title
    attr_reader :slug
    attr_reader :content

    private

    def nested_directory(path_components)
      path_components.reduce(self) { |index, subdirectory| index.add_directory(subdirectory) }
    end
  end

  class Parser
    attr_reader :index

    def initialize(vault_directory)
      @index = Index.new("", "")

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
