# frozen_string_literal: true

RSpec.describe Obsidian::ObsidianFlavoredMarkdown do
  describe ".normalize" do
    it "turns wikilinks into normal links" do
      result = described_class.normalize("[[foo]]")
      expect(result).to eq("[foo](foo)")
    end

    it "uses only the basepath for titles" do
      result = described_class.normalize("[[foo/bar]]")
      expect(result).to eq("[bar](foo/bar)")
    end

    it "uses the custom display name if present" do
      result = described_class.normalize("[[foo/bar|baz]]")
      expect(result).to eq("[baz](foo/bar)")
    end

    # Note: this is part of Github Flavored Markdown
    # See https://github.github.com/gfm/#example-510
    it "includes fragments if present" do
      result = described_class.normalize("[[foo/bar#baz]]")
      expect(result).to eq("[bar](foo/bar#baz)")
    end
  end
end
