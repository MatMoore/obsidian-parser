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

    # Match URLs
    # Pattern based on https://gist.github.com/dperini/729294
    LONE_URL = %r{
      (?<!\S) # not preceeded by a non-whitespace character
      https?:// # Protocol
      (?:\S+(?::\S*)?@)? # basic auth
      (?![-_]) # Not followed by a dash or underscore
      (?:[-\w\u00a1-\uffff]{0,63}[^-_]\.)+ # host and domain names
      (?:[a-z\u00a1-\uffff]{2,}\.?) # top level domain
      (?::\\d{2,5})? # Port number
      (?:[/?#]\\S*)? # Resource path
      (?!\S) # not followed by a non-whitespace character
    }x

    # Workaround for lack of auto-linking in Kramdown.
    # Note: this breaks for URLs included in code blocks.
    def self.auto_link(markdown_text)
      markdown_text.gsub(LONE_URL) do |s|
        "<#{s}>" # Kramdown-specific markup
      end
    end

    # Convert Obsidian-flavored-markdown syntax to something parseable
    # (i.e. with Github-flavored-markdown syntax)
    def self.expand_wikilinks(markdown_text, root:)
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

    def self.normalize(markdown_text, root: nil)
      auto_linked = auto_link(markdown_text)
      return auto_linked if root.nil?

      expand_wikilinks(auto_link(markdown_text), root: root)
    end

    def self.parse(markdown_text, root: nil)
      document = Kramdown::Document.new(normalize(markdown_text, root: root), input: "GFM")
      Obsidian::ParsedMarkdownDocument.new(document)
    end
  end
end
