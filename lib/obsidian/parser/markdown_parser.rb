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

    ATTACHMENT_WIKILINK_SYNTAX = %r{
      !\[\[
      (?<target>[^\]\#|]*) # image or link target
      (?:
        \#(?<fragment>[^|\]]*) # optional heading fragment
      )?
      (?:
        \|(?<text>[^\]]*) # alt text or link display text
      )?
      \]\]
    }x

    # Convert Obsidian-flavored-markdown syntax to something parseable
    # (i.e. with Github-flavored-markdown syntax)
    def expand_wikilinks(markdown_text, root:)
      markdown_text.gsub(WIKILINK_SYNTAX) do |s|
        text = $~[:text]
        target = $~[:target]
        fragment = $~[:fragment]
        link_to_page(text: text, target: target, fragment: fragment, root: root)
      end
    end

    def link_to_page(text:, target:, fragment:, root:)
      page = root.find_in_tree(target)

      if page.nil?
        text.nil? ? target.split("/").last : text
      else
        display_text = text.nil? ? page.title : text
        href = fragment.nil? ? page.uri : "#{page.uri}##{fragment}"

        "[#{display_text}](#{href})"
      end
    end

    def expand_attachments(markdown_text, root:, media_root:)
      markdown_text.gsub(ATTACHMENT_WIKILINK_SYNTAX) do |s|
        text = $~[:text]
        target = $~[:target]
        fragment = $~[:fragment]
        attachment = media_root.find_in_tree(target)

        if attachment.nil?
          # If we attach a page, it is supposed to be displayed inline.
          # However for now, this is unsupported and we'll just fall back to
          # a regular link.
          return link_to_page(text: text, target: target, fragment: fragment, root: root)
        end

        if !attachment.content_type.image?
          # Attachments can also be audio or pdfs.
          # For now just link to these.
          return link_to_page(text: text, target: target, fragment: fragment, root: media_root)
        end

        href = fragment.nil? ? attachment.uri : "#{attachment.uri}##{fragment}"

        "![#{text}](#{href})"
      end
    end

    def parse(markdown_text, root: nil, media_root: nil)
      renderer = HtmlRenderer.new
      normalized1 = expand_attachments(markdown_text, root: root, media_root: media_root)
      normalized2 = expand_wikilinks(normalized1, root: root)
      document = Markly.parse(normalized2, flags: Markly::SMART | Markly::UNSAFE | Markly::HARD_BREAKS, extensions: [:table, :tasklist, :autolink])
      Obsidian::ParsedMarkdownDocument.new(document, renderer: renderer)
    end
  end
end
