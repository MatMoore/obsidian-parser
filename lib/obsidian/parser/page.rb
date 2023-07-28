# frozen_string_literal: true

module Obsidian
  # A page in the vault corresponding to either a markdown document,
  # or a directory containing other documents.
  #
  # If a directory contains an index.md, that is used as the content of
  # the directory page; otherwise content will be nil.
  class Page
    def self.create_root
      Page.new(title: "", slug: "")
    end

    def initialize(title:, slug:, last_modified: nil, content: nil, parent: nil)
      # TODO: check frontmatter for titles as well
      @title = title
      @slug = slug
      @last_modified = last_modified
      @content = content
      @parent = parent
      @children = {}
    end

    def is_index?
      !children.empty?
    end

    def inspect
      "Page(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    def ==(other)
      !slug.nil? && slug == other.slug
    end

    alias_method :eql?, :==

    def hash
      slug.hash
    end

    # Add a note to the tree based on its slug.
    # Call this method on the root page.
    # When calling this method, you must ensure that anscestor pages
    # are added before their descendents.
    def add_page(slug, last_modified: nil, content: nil)
      path_components = slug.split("/")
      raise ArgumentError, "Expecting non-empty slug" if path_components.empty?

      title = path_components.pop

      parent = path_components.reduce(self) do |index, anscestor_title|
        anscestor_slug = Obsidian.build_slug(anscestor_title, index.slug)
        index.get_or_create_child(slug: anscestor_slug, title: anscestor_title)
      end

      parent.get_or_create_child(
        title: title,
        slug: slug,
        last_modified: last_modified,
        content: content
      )
    end

    def get_or_create_child(title:, slug:, last_modified: nil, content: nil)
      # TODO: validate slug matches the current page slug

      @children[title] ||= Page.new(
        slug: slug,
        title: title,
        last_modified: last_modified,
        content: content,
        parent: self
      )
    end

    def children
      @children.values.sort_by { |c| [c.is_index? ? 1 : 0, c.title] }
    end

    attr_reader :title
    attr_reader :slug
    attr_reader :last_modified
    attr_reader :content
    attr_reader :parent
  end
end