# frozen_string_literal: true

RSpec.describe Obsidian::ParsedMarkdownDocument do
  let(:index) { nil }

  def create_instance(markdown)
    Obsidian::ObsidianFlavoredMarkdown.parse(markdown, root: index, renderer: HtmlRenderer.new)
  end

  it "extracts [foo](bar) links" do
    parsed_document = create_instance("here is a link: [foo](bar)")
    links = parsed_document.extract_links
    expect(links).to include(["bar", "foo"])
  end

  it "extracts [foo](bar) links" do
    parsed_document = create_instance("here is a link: [foo](bar)")
    links = parsed_document.extract_links
    expect(links).to include(["bar", "foo"])
  end

  it "extracts links with titles" do
    parsed_document = create_instance('[link](/uri "title")')
    links = parsed_document.extract_links
    expect(links).to include(["/uri", "link"])
  end

  it "extracts links with no destinations" do
    parsed_document = create_instance("[link1]() [link2](<>)")
    links = parsed_document.extract_links
    expect(links).to include(["", "link1"], ["", "link2"])
  end

  it "extracts reference style links" do
    markdown = <<~END
      [foo][bar]

      [bar]: /url "title"
    END

    parsed_document = Obsidian::ObsidianFlavoredMarkdown.parse(markdown, renderer: HtmlRenderer.new)

    links = parsed_document.extract_links

    expect(links).to include(["/url", "foo"])
  end

  it "Extracts raw links" do
    parsed_document = create_instance("http://www.example.com https://www.example.com")
    links = parsed_document.extract_links
    expect(links).to include(["http://www.example.com", "http://www.example.com"], ["https://www.example.com", "https://www.example.com"])
  end

  context "with a document tree" do
    let(:index) { Obsidian::Page.create_root }

    before do
      index.add_page("foo/bar")
      index.add_page("animals/cat")
    end

    it "extracts wikilinks" do
      parsed_document = create_instance("[[animals/cat]]")
      links = parsed_document.extract_links
      expect(links).to include(["animals/cat", "cat"])
    end
  end
end
