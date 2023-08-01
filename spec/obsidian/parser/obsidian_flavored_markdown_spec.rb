# frozen_string_literal: true

RSpec.describe Obsidian::ObsidianFlavoredMarkdown do
  describe ".normalize" do
    let(:index) { Obsidian::Page.create_root }

    before do
      index.add_page("foo/bar")
    end

    it "turns wikilinks into normal links" do
      result = described_class.normalize("[[foo]]", index)
      expect(result).to eq("[foo](foo)")
    end

    it "uses only the basepath for titles" do
      result = described_class.normalize("[[foo/bar]]", index)
      expect(result).to eq("[bar](foo/bar)")
    end

    it "uses the custom display name if present" do
      result = described_class.normalize("[[foo/bar|baz]]", index)
      expect(result).to eq("[baz](foo/bar)")
    end

    # Note: this is part of Github Flavored Markdown
    # See https://github.github.com/gfm/#example-510
    it "includes fragments if present" do
      result = described_class.normalize("[[foo/bar#baz]]", index)
      expect(result).to eq("[bar](foo/bar#baz)")
    end

    it "infers the full slug if a prefix is missing" do
      result = described_class.normalize("[[bar]]", index)
      expect(result).to eq("[bar](foo/bar)")
    end

    it "infers the full slug if a prefix is missing and there is a fragment" do
      result = described_class.normalize("[[bar#baz]]", index)
      expect(result).to eq("[bar](foo/bar#baz)")
    end
  end
end
