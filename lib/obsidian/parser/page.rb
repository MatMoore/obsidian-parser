# frozen_string_literal: true

# TODO: remove this dependency
require "tilt/erb"

module Obsidian
  Page = Struct.new(
    :title,
    :slug,
    :last_modified,
    :source_path,
    :content_type,
    keyword_init: true
  ) do
    # TODO: remove dependency on root and media root
    # instead, MarkdownParser should be passed a reference to the vault
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
end
