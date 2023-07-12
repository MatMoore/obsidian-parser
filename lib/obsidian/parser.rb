# frozen_string_literal: true

require_relative "parser/version"

module Obsidian
  class Error < StandardError; end

  class Note
    def initialize(path, last_modified)
      # TODO: check frontmatter for titles as well
      @title = path.basename.to_s.gsub(/\.md\z/, "")
      @parent = path.dirname

      @slug = path.to_s.gsub(/\.md\z/, "")

      @last_modified = last_modified
    end

    def inspect
      "Note(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    attr_reader :title
    attr_reader :slug
    attr_reader :parent
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
      new_slug = if slug == ""
        title
      else
        [slug, title].join("/")
      end

      @directories[title] ||= Index.new(title, new_slug)
    end

    def add_note(title, parent_slug, last_modified)
      note = Note.new(parent_slug + title, last_modified)

      directory = nested_directory(parent_slug.to_s.split("/").reject { |c| c == "." })
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
          if dirname == "."
            dirname = ""
          end

          @index.add_note(basename, dirname, path.mtime)
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
