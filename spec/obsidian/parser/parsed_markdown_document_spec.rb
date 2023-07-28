# frozen_string_literal: true

RSpec.describe Obsidian::ParsedMarkdownDocument do
  it "extracts [foo](bar) links" do
    markdown = "here is a link: [foo](bar)"

    converter = Obsidian::ObsidianFlavoredMarkdown.parse(markdown)
    links = converter.extract_links

    expect(links).to include(["bar", "foo"])
  end

  it "extracts [foo](bar) links" do
    markdown = "here is a link: [foo](bar)"

    converter = Obsidian::ObsidianFlavoredMarkdown.parse(markdown)
    links = converter.extract_links

    expect(links).to include(["bar", "foo"])
  end

  it "extracts links with titles" do
    markdown = '[link](/uri "title")'
    converter = Obsidian::ObsidianFlavoredMarkdown.parse(markdown)
    links = converter.extract_links

    expect(links).to include(["/uri", "link"])
  end

  it "extracts links with no destinations" do
    markdown = "[link1]() [link2](<>)"

    converter = Obsidian::ObsidianFlavoredMarkdown.parse(markdown)
    links = converter.extract_links

    expect(links).to include(["", "link1"], ["", "link2"])
  end

  it "extracts reference style links" do
    markdown = <<~END
      [foo][bar]

      [bar]: /url "title"
    END

    converter = Obsidian::ObsidianFlavoredMarkdown.parse(markdown)
    links = converter.extract_links

    expect(links).to include(["/url", "foo"])
  end

  it "extracts wikilinks" do
    markdown = "[[animals/cat]]"

    converter = Obsidian::ObsidianFlavoredMarkdown.parse(markdown)
    links = converter.extract_links

    expect(links).to include(["animals/cat", "cat"])
  end
end
