# frozen_string_literal: true

RSpec.describe(Obsidian::MarkdownParser::FrontMatterParser) do
  subject(:parser) { described_class.new }

  it "parses valid yaml" do
    content = %(---
foo: 1
bar: banana
---
some text
    )
    expect(parser.parse(content)).to eq({"foo" => 1, "bar" => "banana"})
  end

  it "returns empty hash for invalid yaml" do
    content = %(---
{
---
some text
    )
    expect(parser.parse(content)).to eq({})
  end

  it "returns empty hash if the frontmatter is not terminated" do
    content = %(---
some text
    )
    expect(parser.parse(content)).to eq({})
  end

  it "returns empty hash if no frontmatter" do
    content = "hello world"
    expect(parser.parse(content)).to eq({})
  end
end
