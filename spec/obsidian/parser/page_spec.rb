# frozen_string_literal: true

RSpec.describe Obsidian::Page do
  subject(:root) { described_class.create_root }

  describe("#add_page") do
    it "relates too pages" do
      page = root.add_page("foo")

      expect(page.parent).to eq(root)
      expect(root.children).to eq([page])
    end

    it "assigns titles and slugs to a top level page" do
      page = root.add_page("foo")

      expect(page.slug).to eq("foo")
      expect(page.title).to eq("foo")
    end

    it "assigns titles and slugs to a nested page" do
      page = root.add_page("foo/bar/baz")

      expect(page.slug).to eq("foo/bar/baz")
      expect(page.title).to eq("baz")
    end

    it "infers missing directory pages" do
      page = root.add_page("foo/bar/baz")
      parent = page.parent
      grandparent = parent.parent

      expect(parent.slug).to eq("foo/bar")
      expect(grandparent.slug).to eq("foo")
      expect(parent.children).to eq([page])
      expect(grandparent.children).to eq([parent])
      expect(root.children).to eq([grandparent])
    end
  end
end
