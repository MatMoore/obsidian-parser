# frozen_string_literal: true

module Obsidian
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
      Page.new(title: "", slug: "")
    end

    def initialize(title:, slug:, last_modified: nil, content: nil, parent: nil, content_type: nil, media_root: nil)
      # TODO: check frontmatter for titles as well
      @title = title
      @slug = slug
      @last_modified = last_modified
      @content = content
      @parent = parent
      @root = parent.nil? ? self : parent.root
      @children = {}
      @content_type = content_type
      @media_root = media_root
    end

    def is_index?
      !children.empty?
    end

    def inspect
      "Page(title: #{title.inspect}, slug: #{slug.inspect})"
    end

    # Apply percent encoding to the slug
    def uri
      if slug == ""
        "/"
      else
        "/" + slug.split("/").map { |part| ERB::Util.url_encode(part) }.join("/")
      end
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

    # Add a note to the tree based on its slug.
    # Call this method on the root page.
    # When calling this method, you must ensure that anscestor pages
    # are added before their descendents.
    def add_page(slug, last_modified: nil, content: nil, content_type: nil, media_root: nil)
      path_components = slug.split("/")

      if path_components.empty?
        update_content(content: content, last_modified: last_modified)
        return
      end

      title = path_components.pop

      parent = path_components.reduce(self) do |index, anscestor_title|
        anscestor_slug = Obsidian.build_slug(anscestor_title, index.slug)
        index.get_or_create_child(slug: anscestor_slug, title: anscestor_title)
      end

      parent.get_or_create_child(
        title: title,
        slug: slug,
        last_modified: last_modified,
        content: content,
        content_type: content_type,
        media_root: media_root
      ).tap do |page|
        page.update_content(content: content, last_modified: last_modified)
      end
    end

    def get_or_create_child(title:, slug:, last_modified: nil, content: nil, content_type: nil, media_root: nil)
      # TODO: validate slug matches the current page slug

      @children[title] ||= Page.new(
        slug: slug,
        title: title,
        last_modified: last_modified,
        content: content,
        content_type: content_type,
        parent: self,
        media_root: media_root
      )
    end

    def update_content(content:, last_modified:)
      @content ||= content
      @last_modified ||= last_modified
    end

    def children
      @children.values.sort_by { |c| [c.is_index? ? 0 : 1, c.title] }
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

    def generate_html(markdown_parser: MarkdownParser.new)
      return nil if content.nil?

      markdown_parser.parse(content.call, root: root, media_root: media_root).to_html
    end

    attr_reader :title
    attr_reader :slug
    attr_reader :last_modified
    attr_reader :content
    attr_reader :content_type
    attr_reader :parent
    attr_reader :root
    attr_reader :media_root
  end
end
