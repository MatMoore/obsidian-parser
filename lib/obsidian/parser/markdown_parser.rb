# frozen_string_literal: true

require "markly"

module Obsidian
  class MarkdownParser
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

    def initialize(renderer: HtmlRenderer.new)
      @renderer = renderer
    end

    # Convert Obsidian-flavored-markdown syntax to something parseable
    # (i.e. with Github-flavored-markdown syntax)
    def expand_wikilinks(markdown_text, root:)
      markdown_text.gsub(WIKILINK_SYNTAX) do |s|
        text = $~[:text]
        target = $~[:target]
        fragment = $~[:fragment]
        page = root.find_in_tree(target)

        if page.nil?
          text.nil? ? target.split("/").last : text
        else
          display_text = text.nil? ? page.slug.split("/").last : text
          href = fragment.nil? ? page.slug : "#{page.slug}##{fragment}"

          "[#{display_text}](#{href})"
        end
      end
    end

    def parse(markdown_text, root: nil)
      normalized = expand_wikilinks(markdown_text, root: root)
      document = Markly.parse(normalized, flags: Markly::SMART | Markly::UNSAFE | Markly::HARD_BREAKS, extensions: [:table, :tasklist, :autolink])
      Obsidian::ParsedMarkdownDocument.new(document, renderer: renderer)
    end

    private

    attr_reader :renderer
  end
end