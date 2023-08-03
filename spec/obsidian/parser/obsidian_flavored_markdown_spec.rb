# frozen_string_literal: true

RSpec.describe Obsidian::ObsidianFlavoredMarkdown do
  describe ".expand_wikilinks" do
    let(:index) { Obsidian::Page.create_root }

    before do
      index.add_page("foo/bar")
    end

    it "turns wikilinks into normal links" do
      result = described_class.expand_wikilinks("[[foo]]", root: index)
      expect(result).to eq("[foo](foo)")
    end

    it "de-linkifies wikilinks that don't go away" do
      result = described_class.expand_wikilinks("[[missing-link]] [[foo]]", root: index)
      expect(result).to eq("missing-link [foo](foo)")
    end

    it "uses only the basepath for titles" do
      result = described_class.expand_wikilinks("[[foo/bar]]", root: index)
      expect(result).to eq("[bar](foo/bar)")
    end

    it "uses the custom display name if present" do
      result = described_class.expand_wikilinks("[[foo/bar|baz]]", root: index)
      expect(result).to eq("[baz](foo/bar)")
    end

    # Note: this is part of Github Flavored Markdown
    # See https://github.github.com/gfm/#example-510
    it "includes fragments if present" do
      result = described_class.expand_wikilinks("[[foo/bar#baz]]", root: index)
      expect(result).to eq("[bar](foo/bar#baz)")
    end

    it "infers the full slug if a prefix is missing" do
      result = described_class.expand_wikilinks("[[bar]]", root: index)
      expect(result).to eq("[bar](foo/bar)")
    end

    it "infers the full slug if a prefix is missing and there is a fragment" do
      result = described_class.expand_wikilinks("[[bar#baz]]", root: index)
      expect(result).to eq("[bar](foo/bar#baz)")
    end

    it "expands wikilinks pointing to index files" do
      result = described_class.expand_wikilinks("[[foo/index]]", root: index)
      expect(result).to eq("[foo](foo)")
    end

    it "expands wikilinks pointing to index files with custom display names" do
      result = described_class.expand_wikilinks("[[foo/index|bla]]", root: index)
      expect(result).to eq("[bla](foo)")
    end
  end
end
