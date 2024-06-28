# frozen_string_literal: true

# TODO: remove this dependency
require "tilt/erb"
require_relative "tree"

module Obsidian
  # WIP
  PageNode = Struct.new(
    :title,
    :slug,
    :last_modified,
    :source_path,
    :content_type,
    keyword_init: true
  ) do
    def parse
    end

    def uri
      if slug == ""
        "/"
      else
        "/" + slug.split("/").map { |part| ERB::Util.url_encode(part) }.join("/")
      end
    end
  end

  ParsedPage = Struct.new(
    :metadata,
    :raw_content,
    :html,
    keyword_init: true
  )

  # A page in the vault corresponding to either a markdown document,
  # or a directory containing other documents.
  #
  # If a directory contains an index.md, that will become the directory
  # index page. Otherwise, the index page is inferred and will have no
  # content (#generate_html will return nil).
  #
  # Each page belongs to a tree of pages nested under the root page
  # (the one with slug = "").
  #
  # Pages may optionally be associated with a media root, which is
  # a separate tree containing attachment files. If this is present,
  # markdown rendering will take into account these attachments when
  # encountering wikilink syntax.
  class Page
    def self.create_root
      legacy_initialize(title: "", slug: "")
    end

    def self.legacy_initialize(title:, slug:, last_modified: nil, content: nil, parent: nil, content_type: nil, media_root: nil, source_path: nil, content_store: {})
      # TODO: check frontmatter for titles as well
      node = PageNode.new(title: title, slug: slug, last_modified: last_modified, content_type: content_type, source_path: source_path)

      # Migration step:
      # - use tree to store metadata about the file
      # - but use content_store to store the content callbacks
      tree = Tree.new(node)
      content_store[slug] = content unless content.nil?

      Page.new(tree, content_store, parent: parent, media_root: media_root)
    end

    def initialize(tree, content_store, parent: nil, root: nil, media_root: nil)
      @tree = tree
      @content_store = content_store
      @content = content
      @parent = parent
      @media_root = media_root
      @referenced = false
      @child_pages = {}
      @root = root || self
    end

    attr_reader :parent

    def is_index?
      !@tree.children.empty?
    end

    def inspect
      "Page(tree=#{@tree.inspect})"
    end

    def value
      @tree.value
    end

    def uri
      @tree.value.uri
    end

    def ==(other)
      self.class == other.class &&
        !slug.nil? &&
        slug == other&.slug
    end

    alias_method :eql?, :==

    def hash
      slug.hash
    end

    def slug
      @tree.value.slug
    end

    def content
      @content_store[slug]
    end

    def title
      @tree.value.title
    end

    def content_type
      @tree.value.content_type
    end

    def last_modified
      @tree.value.last_modified
    end

    def source_path
      @tree.value.source_path
    end

    # Add a note to the tree based on its slug.
    # Call this method on the root page.
    # When calling this method, you must ensure that anscestor pages
    # are added before their descendents.
    def add_page(slug, last_modified: nil, content: nil, content_type: nil, media_root: nil, source_path: nil, strip_numeric_prefix: true)
      path_components = slug.split("/")

      if path_components.empty?
        update_content(content: content, last_modified: last_modified, source_path: source_path)
        return
      end

      title = path_components.pop
      if strip_numeric_prefix
        title = title.sub(/^\d+ - /, "")
      end

      parent = path_components.reduce(self) do |index, anscestor_title|
        anscestor_slug = Obsidian.build_slug(anscestor_title, index.slug)
        index.get_or_create_child(slug: anscestor_slug, title: anscestor_title.sub(/^\d+ - /, ""))
      end

      parent.get_or_create_child(
        title: title,
        slug: slug,
        last_modified: last_modified,
        content: content,
        content_type: content_type,
        media_root: media_root,
        source_path: source_path
      ).tap do |page|
        page.update_content(content: content, last_modified: last_modified, source_path: source_path)
      end
    end

    def get_or_create_child(title:, slug:, last_modified: nil, content: nil, content_type: nil, media_root: nil, source_path: nil)
      # TODO: validate slug matches the current page slug

      value = PageNode.new(
        slug: slug,
        title: title,
        last_modified: last_modified,
        content_type: content_type,
        source_path: source_path
      )

      child = @tree.add_child_unless_exists(value.slug, value)
      @content_store[slug] = content unless content.nil?
      page = Page.new(child, @content_store, parent: self, root: root, media_root: media_root)
      @child_pages[slug] ||= page
    end

    def update_content(content:, last_modified:, source_path:)
      @content_store[slug] ||= content
      @tree.value.last_modified ||= last_modified
      @tree.value.source_path ||= source_path
    end

    def children
      nodes = @tree.children
      nodes.map { |node| @child_pages[node.value.slug] }.sort_by { |c| [c.is_index? ? 0 : 1, c.slug] }
    end

    def walk_tree(&block)
      block.call(self)

      children.each do |page|
        page.walk_tree(&block)
      end
    end

    # Return the page that matches a slug.
    # If there is an exact match, we should always return that
    # Otherwise, if we can skip over some anscestors and get a
    # match, then return the first, shortest match.
    # If a query slug contains `/index` we ignore it and treat it
    # the same as `/`
    def find_in_tree(query_slug)
      # Exact match
      return self if slug == query_slug

      # Partial match
      query_parts = query_slug.split("/").reject { |part| part == "index" }
      length = query_parts.size
      slug_parts = slug.split("/")

      if slug_parts.length >= length
        if slug_parts.slice(-length, length) == query_parts
          return self
        end
      end

      # Recurse
      children.each do |child|
        result = child.find_in_tree(query_slug)
        return result unless result.nil?
      end

      nil
    end

    def parse(markdown_parser: MarkdownParser.new)
      return nil if content.nil?

      markdown_parser.parse(content.call, root: root, media_root: media_root)
    end

    def generate_html(markdown_parser: MarkdownParser.new)
      parse(markdown_parser: markdown_parser)&.to_html
    end

    def referenced?
      @referenced
    end

    # Mark the tree containing this page as being "referenced"
    # i.e. reachable through links
    def mark_referenced
      @referenced = true
      parent&.mark_referenced
    end

    # Remove any child paths that are unreferenced,
    # i.e. not reachable through links
    def prune!
      @tree.remove_all do |value|
        !find_in_tree(value.slug).referenced?
      end
    end

    attr_reader :root
    attr_reader :media_root
  end
end
