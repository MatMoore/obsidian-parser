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
    def self.normalize(markdown_text)
      markdown_text.gsub(WIKILINK_SYNTAX) do |s|
        text = $~[:text]
        target = $~[:target]
        fragment = $~[:fragment]
        display_text = text.nil? ? target.split("/").last : text
        href = fragment.nil? ? target : "#{target}##{fragment}"

        "[#{display_text}](#{href})"
      end
    end

    # Parse links from obsidian-flavored-markdown text
    def self.parse(markdown_text)
      document = Kramdown::Document.new(normalize(markdown_text), input: "GFM")
      Obsidian::MarkdownConverter.new(document)
    end
  end
end
