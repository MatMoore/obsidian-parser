# frozen_string_literal: true

require_relative "parser/version"

module Obsidian
  class Error < StandardError; end

  class Note
    def initialize(path, last_modified)
      # TODO: check frontmatter for titles as well
      @title = path.basename.to_s.gsub(/\.md\z/, '')

      @slug = path.to_s.gsub(/\.md\z/, '')

      @last_modified = last_modified
    end

    def inspect
      "Note(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    attr_reader :title
    attr_reader :slug
    attr_reader :last_modified
  end

  class Parser
    def initialize(vault_directory)
      # TODO: capture directories and index files as well

      @notes_by_slug = {}

      vault_directory.glob('**/*.md').each do |path|
        note = Note.new(path.relative_path_from(vault_directory), path.mtime)
        @notes_by_slug[note.slug] = note
      end

      # TODO: capture links between notes
    end

    def notes
      @notes_by_slug.values
    end
  end
end
