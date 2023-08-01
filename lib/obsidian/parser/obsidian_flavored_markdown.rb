# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module Obsidian
  module ObsidianFlavoredMarkdown
    WIKILINK_SYNTAX = %r{
      \[\[
      (?<target>[^\]\#|]*) # link target
      (?:
        \#(?<fragment>[^|\]]*) # optional heading fragment
      )?
      (?:
        \|(?<text>[^\]]*) # optional link display text
      )?
      \]\]
    }x

    # Convert Obsidian-flavored-markdown syntax to something parseable
    # (i.e. with Github-flavored-markdown syntax)
    def self.normalize(markdown_text, root)
      markdown_text.gsub(WIKILINK_SYNTAX) do |s|
        text = $~[:text]
        target = $~[:target]
        fragment = $~[:fragment]
        page = root.find_in_tree(target)
        return text.nil? ? target.split("/").last : text if page.nil?

        display_text = text.nil? ? page.slug.split("/").last : text
        href = fragment.nil? ? page.slug : "#{page.slug}##{fragment}"

        "[#{display_text}](#{href})"
      end
    end

    # Parse links from obsidian-flavored-markdown text
    def self.parse(markdown_text, root)
      document = Kramdown::Document.new(normalize(markdown_text, root), input: "GFM")
      Obsidian::ParsedMarkdownDocument.new(document)
    end
  end
end
