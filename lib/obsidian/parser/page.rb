# frozen_string_literal: true

# TODO: remove this dependency
require "tilt/erb"
require_relative "tree"

module Obsidian
  PageNode = Struct.new(
    :title,
    :slug,
    :last_modified,
    :source_path,
    :content_type,
    keyword_init: true
  ) do
    # TODO: remove dependency on root and media root
    # instead, MarkdownParser should be parsed a reference to the vault
    def parse(root:, media_root:, markdown_parser: MarkdownParser.new)
      return nil if source_path.nil?

      content = source_path.read
      parsed_doc = markdown_parser.parse(content, root: root, media_root: media_root)
      ParsedPage.new(metadata: self, raw_content: content, html: parsed_doc.to_html, frontmatter: parsed_doc.frontmatter)
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
    :frontmatter,
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

    def self.legacy_initialize(title:, slug:, last_modified: nil, parent: nil, content_type: nil, media_root: nil, source_path: nil)
      # TODO: check frontmatter for titles as well
      node = PageNode.new(title: title, slug: slug, last_modified: last_modified, content_type: content_type, source_path: source_path)

      tree = Tree.new(node, order_by: @ordering)

      Page.new(tree, parent: parent, media_root: media_root)
    end

    def initialize(tree, parent: nil, root: nil, media_root: nil, referenced_slugs: {})
      @tree = tree
      @parent = parent
      @media_root = media_root
      @referenced_slugs = referenced_slugs
      @root = root || self
      @ordering = proc { |c| [c.children.empty? ? 0 : 1, c.value.slug] }
    end

    attr_reader :parent

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
    def add_page(slug, last_modified: nil, content_type: nil, media_root: nil, source_path: nil, strip_numeric_prefix: true)
      path_components = slug.split("/")

      if path_components.empty?
        update_source(last_modified: last_modified, source_path: source_path)
        return
      end

      title = path_components.pop
      if strip_numeric_prefix
        title = title.sub(/^\d+ - /, "")
      end

      parent = path_components.reduce(self) do |index, anscestor_title|
        anscestor_slug = Obsidian.build_slug(anscestor_title, index.slug)
        index.get_or_create_child(
          slug: anscestor_slug,
          title: anscestor_title.sub(/^\d+ - /, ""),
          media_root: media_root
        )
      end

      parent.get_or_create_child(
        title: title,
        slug: slug,
        last_modified: last_modified,
        content_type: content_type,
        media_root: media_root,
        source_path: source_path
      ).tap do |page|
        page.update_source(last_modified: last_modified, source_path: source_path)
      end
    end

    def get_or_create_child(title:, slug:, last_modified: nil, content_type: nil, media_root: nil, source_path: nil)
      # TODO: validate slug matches the current page slug

      value = PageNode.new(
        slug: slug,
        title: title,
        last_modified: last_modified,
        content_type: content_type,
        source_path: source_path
      )

      child = @tree.add_child_unless_exists(value.slug, value)
      Page.new(child, parent: self, root: root, media_root: media_root, referenced_slugs: @referenced_slugs)
    end

    def update_source(last_modified:, source_path:)
      @tree.value.last_modified ||= last_modified
      @tree.value.source_path ||= source_path
    end

    attr_reader :tree

    # Return the page that matches a slug.
    # If there is an exact match, we should always return that
    # Otherwise, if we can skip over some anscestors and get a
    # match, then return the first, shortest match.
    # If a query slug contains `/index` we ignore it and treat it
    # the same as `/`
    def find_in_tree(query_slug, search_tree: @tree)
      slug = search_tree.value.slug

      # Exact match
      return search_tree if slug == query_slug

      # Partial match
      query_parts = query_slug.split("/").reject { |part| part == "index" }
      length = query_parts.size
      slug_parts = slug.split("/")

      if slug_parts.length >= length
        if slug_parts.slice(-length, length) == query_parts
          return search_tree
        end
      end

      # Recurse
      search_tree.children.each do |child|
        result = find_in_tree(query_slug, search_tree: child)
        return result unless result.nil?
      end

      nil
    end

    # deprecated
    def parse(markdown_parser: MarkdownParser.new)
      @tree.value.parse(root: root, media_root: media_root, markdown_parser: markdown_parser)
    end

    # deprecated
    def generate_html(markdown_parser: MarkdownParser.new)
      parse(markdown_parser: markdown_parser).html
    end

    # Mark the tree containing this page as being "referenced"
    # i.e. reachable through links
    def mark_referenced
      @referenced_slugs[tree.value.slug] = true
      tree.anscestors.each do |a|
        @referenced_slugs[a.value.slug] = true
      end
    end

    def referenced?(slug)
      @referenced_slugs[slug] == true
    end

    # Remove any child paths that are unreferenced,
    # i.e. not reachable through links
    def prune!
      @tree.remove_all do |value|
        !@referenced_slugs[value.slug]
      end
    end

    attr_reader :root
    attr_reader :media_root
  end
end
