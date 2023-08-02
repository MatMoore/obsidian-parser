# frozen_string_literal: true

RSpec.describe Obsidian::ObsidianFlavoredMarkdown do
  describe ".normalize" do
    let(:index) { Obsidian::Page.create_root }

    before do
      index.add_page("foo/bar")
    end

    it "turns wikilinks into normal links" do
      result = described_class.normalize("[[foo]]", root: index)
      expect(result).to eq("[foo](foo)")
    end

    it "de-linkifies wikilinks that don't go away" do
      result = described_class.normalize("[[missing-link]] [[foo]]", root: index)
      expect(result).to eq("missing-link [foo](foo)")
    end

    it "uses only the basepath for titles" do
      result = described_class.normalize("[[foo/bar]]", root: index)
      expect(result).to eq("[bar](foo/bar)")
    end

    it "uses the custom display name if present" do
      result = described_class.normalize("[[foo/bar|baz]]", root: index)
      expect(result).to eq("[baz](foo/bar)")
    end

    # Note: this is part of Github Flavored Markdown
    # See https://github.github.com/gfm/#example-510
    it "includes fragments if present" do
      result = described_class.normalize("[[foo/bar#baz]]", root: index)
      expect(result).to eq("[bar](foo/bar#baz)")
    end

    it "infers the full slug if a prefix is missing" do
      result = described_class.normalize("[[bar]]", root: index)
      expect(result).to eq("[bar](foo/bar)")
    end

    it "infers the full slug if a prefix is missing and there is a fragment" do
      result = described_class.normalize("[[bar#baz]]", root: index)
      expect(result).to eq("[bar](foo/bar#baz)")
    end

    it "autolinks full urls" do
      result = described_class.normalize("hello https://www.google.com")
      expect(result).to eq("hello <https://www.google.com>")
    end

    it "doesn't autolink URLs in backticks" do
      result = described_class.normalize("hello `https://www.google.com`")
      expect(result).to eq("hello `https://www.google.com`")
    end

    it "doesn't autolink URLs in parens" do
      result = described_class.normalize("hello (https://www.google.com)")
      expect(result).to eq("hello (https://www.google.com)")
    end

    it "doesn't autolink URLs in square brackets" do
      result = described_class.normalize("hello [https://www.google.com]")
      expect(result).to eq("hello [https://www.google.com]")
    end

    it "doesn't autolink URLs in angle brackets" do
      result = described_class.normalize("hello <https://www.google.com>")
      expect(result).to eq("hello <https://www.google.com>")
    end

    it "doesn't autolink URLs appended to other text" do
      result = described_class.normalize("hellohttps://www.google.com")
      expect(result).to eq("hellohttps://www.google.com")
    end
  end
end
