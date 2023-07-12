# frozen_string_literal: true
require 'kramdown'
require 'kramdown-parser-gfm'

RSpec.describe Obsidian::MarkdownConverter do
  it "extracts [foo](bar) links" do
    markdown = "here is a link: [foo](bar)"

    document = Kramdown::Document.new(markdown, input: "GFM")
    converter = Obsidian::MarkdownConverter.new(document)
    links = converter.extract_links

    expect(links).to include(["bar", "foo"])
  end

  it "extracts [foo](bar) links" do
    markdown = "here is a link: [foo](bar)"

    document = Kramdown::Document.new(markdown, input: "GFM")
    converter = Obsidian::MarkdownConverter.new(document)
    links = converter.extract_links

    expect(links).to include(["bar", "foo"])
  end

  it "extracts links with titles" do
    markdown = '[link](/uri "title")'
    document = Kramdown::Document.new(markdown, input: "GFM")
    converter = Obsidian::MarkdownConverter.new(document)
    links = converter.extract_links

    expect(links).to include(["/uri", "link"])
  end

  it "extracts links with no destinations" do
    markdown = "[link1]() [link2](<>)"

    document = Kramdown::Document.new(markdown, input: "GFM")
    converter = Obsidian::MarkdownConverter.new(document)
    links = converter.extract_links

    expect(links).to include(["", "link1"], ["", "link2"])
  end

  it "extracts reference style links" do
    markdown = <<~END
      [foo][bar]

      [bar]: /url "title"
    END

    document = Kramdown::Document.new(markdown, input: "GFM")
    converter = Obsidian::MarkdownConverter.new(document)
    links = converter.extract_links

    expect(links).to include(["/url", "foo"])
  end
end
