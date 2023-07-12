# frozen_string_literal: true

require_relative "parser/version"
require_relative "parser/markdown_converter"

module Obsidian
  class Error < StandardError; end

  def self.build_slug(title, parent_slug)
    (parent_slug == "") ? title : "#{parent_slug}/#{title}"
  end

  class Note
    def initialize(title, slug, last_modified)
      # TODO: check frontmatter for titles as well
      @title = title
      @slug = slug
      @last_modified = last_modified
    end

    def inspect
      "Note(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    attr_reader :title
    attr_reader :slug
    attr_reader :last_modified
  end

  class Index
    def initialize(title = "", slug = "")
      @title = title
      @slug = slug
      @notes = []
      @directories = {}
    end

    def add_directory(title)
      new_slug = Obsidian.build_slug(title, slug)
      @directories[title] ||= Index.new(title, new_slug)
    end

    def add_note(title, parent_slug, last_modified)
      slug = Obsidian.build_slug(title, parent_slug)
      directory = nested_directory(parent_slug.split("/"))
      note = Note.new(title, slug, last_modified)

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

        if basename != "index.md" && basename != "."
          title = basename.to_s.gsub(/\.md\z/, "")
          parent_slug = dirname.to_s.gsub(/\A\.\/?/, "")
          @index.add_note(title, parent_slug, path.mtime)
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
