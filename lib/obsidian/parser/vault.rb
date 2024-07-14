# frozen_string_literal: true

require_relative "tree"
require_relative "page"

module Obsidian
  # The vault is a hierarchical structure where each node
  # corresponds to either a markdown document,
  # or a directory containing other documents.
  #
  # If a directory contains an index.md, that will be used
  # as the `source_path` for the directory.
  #
  # The root node has slug="" and title=""
  #
  # The vault may optionally be associated with a media root, which is
  # a separate tree containing attachment files. If this is present,
  # markdown rendering will take into account these attachments when
  # encountering wikilink syntax.
  class Vault
    def self.create_root
      node = Page.new(title: "", slug: "", last_modified: nil, content_type: nil, source_path: nil)
      tree = Tree.new(node, order_by: @ordering)
      Vault.new(tree)
    end

    # TODO: make root and media_root trees
    def initialize(tree, media_root: nil, referenced_slugs: {})
      @tree = tree
      @media_root = media_root
      @referenced_slugs = referenced_slugs

      # The order that child nodes are sorted for display
      @ordering = proc { |c| [c.children.empty? ? 0 : 1, c.value.slug] }
    end

    def inspect
      "Vault(tree=#{@tree.inspect})"
    end

    # Add a note to the tree based on its slug.
    def add_page(slug, last_modified: nil, content_type: nil, media_root: nil, source_path: nil, strip_numeric_prefix: true)
      path_components = slug.split("/")

      # Update the source of the root
      if path_components.empty?
        tree.value.source_path ||= source_path
        tree.value.last_modified ||= last_modified
        return
      end

      # Get the title of the page being added
      title = path_components.pop
      if strip_numeric_prefix
        title = title.sub(/^\d+ - /, "")
      end

      # Create intermediate pages
      parent = path_components.reduce(@tree) do |subtree, anscestor_title|
        anscestor_slug = Obsidian.build_slug(anscestor_title, subtree.value.slug)

        value = Page.new(
          slug: anscestor_slug,
          title: anscestor_title.sub(/^\d+ - /, ""),
          last_modified: last_modified,
          content_type: nil,
          source_path: nil
        )

        subtree.add_child_unless_exists(value.slug, value)
      end

      # Create the page
      value = Page.new(
        slug: slug,
        title: title,
        last_modified: last_modified,
        content_type: content_type,
        source_path: source_path
      )
      page = parent.add_child_unless_exists(
        value.slug,
        value
      )
      page.value.source_path ||= source_path
      page.value.last_modified ||= last_modified

      page
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

    # Mark the tree containing this page as being "referenced"
    # i.e. reachable through links
    def mark_referenced(slug)
      @referenced_slugs[slug] = true

      subtree = find_in_tree(slug)
      subtree.anscestors.each do |a|
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
        !referenced?(value.slug)
      end
    end

    attr_reader :root
    attr_reader :media_root
  end
end
