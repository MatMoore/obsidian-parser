# frozen_string_literal: true

RSpec.describe Obsidian::MarkdownParser do
  subject(:parser) { described_class.new }

  describe "#expand_wikilinks" do
    let(:index) { Obsidian::Vault.create_root }

    before do
      index.add_page("foo/bar")
    end

    it "turns wikilinks into normal links" do
      result = parser.expand_wikilinks("[[foo]]", root: index)
      expect(result).to eq("[foo](/foo)")
    end

    it "de-linkifies wikilinks that don't go away" do
      result = parser.expand_wikilinks("[[missing-link]] [[foo]]", root: index)
      expect(result).to eq("missing-link [foo](/foo)")
    end

    it "uses only the basepath for titles" do
      result = parser.expand_wikilinks("[[foo/bar]]", root: index)
      expect(result).to eq("[bar](/foo/bar)")
    end

    it "uses the custom display name if present" do
      result = parser.expand_wikilinks("[[foo/bar|baz]]", root: index)
      expect(result).to eq("[baz](/foo/bar)")
    end

    # Note: this is part of Github Flavored Markdown
    # See https://github.github.com/gfm/#example-510
    it "includes fragments if present" do
      result = parser.expand_wikilinks("[[foo/bar#baz]]", root: index)
      expect(result).to eq("[bar](/foo/bar#baz)")
    end

    it "infers the full slug if a prefix is missing" do
      result = parser.expand_wikilinks("[[bar]]", root: index)
      expect(result).to eq("[bar](/foo/bar)")
    end

    it "infers the full slug if a prefix is missing and there is a fragment" do
      result = parser.expand_wikilinks("[[bar#baz]]", root: index)
      expect(result).to eq("[bar](/foo/bar#baz)")
    end

    it "expands wikilinks pointing to index files" do
      result = parser.expand_wikilinks("[[foo/index]]", root: index)
      expect(result).to eq("[foo](/foo)")
    end

    it "expands wikilinks pointing to index files with custom display names" do
      result = parser.expand_wikilinks("[[foo/index|bla]]", root: index)
      expect(result).to eq("[bla](/foo)")
    end

    it "URL encodes wiklink targets that have spaces in them" do
      index.add_page("foo/page with spaces")
      result = parser.expand_wikilinks("[[page with spaces]]", root: index)
      expect(result).to eq("[page with spaces](/foo/page%20with%20spaces)")
    end

    context "with attachments" do
      let(:media_root) { Obsidian::Vault.create_root }

      before do
        path = Pathname.new(__dir__).join("../../example_vault/foo/bar.jpg")
        media_root.add_page("foo/bar.jpg", content_type: ContentType.new(path))

        path = Pathname.new(__dir__).join("../../example_vault/hello_world.txt")
        media_root.add_page("hello_world.txt", content_type: ContentType.new(path))
      end

      it "expands image wikilinks" do
        result = parser.expand_attachments("![[foo/bar.jpg]]", root: index, media_root: media_root)
        expect(result).to eq("![](/foo/bar.jpg)")
      end

      it "expands image wikilinks that leave out a prefix" do
        result = parser.expand_attachments("![[bar.jpg]]", root: index, media_root: media_root)
        expect(result).to eq("![](/foo/bar.jpg)")
      end

      it "expands image wikilinks that leave out a prefix" do
        result = parser.expand_attachments("![[bar.jpg]]", root: index, media_root: media_root)
        expect(result).to eq("![](/foo/bar.jpg)")
      end

      it "includes alt text for image wikilinks" do
        result = parser.expand_attachments("![[bar.jpg|a man walks into a bar]]", root: index, media_root: media_root)
        expect(result).to eq("![a man walks into a bar](/foo/bar.jpg)")
      end

      it "falls back to a link if the target is a regular markdown document" do
        index.add_page("foo/bar")
        result = parser.expand_attachments("![[bar]]", root: index, media_root: media_root)
        expect(result).to eq("[bar](/foo/bar)")
      end

      it "falls back to a link if the target is not an image" do
        result = parser.expand_attachments("![[hello_world.txt]]", root: index, media_root: media_root)
        expect(result).to eq("[hello_world.txt](/hello_world.txt)")
      end

      it "falls back to plain text if there is no such page" do
        result = parser.expand_attachments("![[banana|a yellow banana]]", root: index, media_root: media_root)
        expect(result).to eq("a yellow banana")
      end
    end
  end

  describe "#parse" do
    it "parses frontmatter if available" do
      content = %(---
        foo: 1
        bar: banana
---
        some text
      )
      result = parser.parse(content)
      expect(result.frontmatter).to eq("foo" => 1, "bar" => "banana")
    end

    it "returns empty frontmatter if not available" do
      content = "some text"
      result = parser.parse(content)
      expect(result.frontmatter).to eq({})
    end
  end
end
