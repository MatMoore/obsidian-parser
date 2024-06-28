# frozen_string_literal: true

RSpec.describe Obsidian::Page do
  subject(:root) { described_class.create_root }

  describe("#add_page") do
    it "relates two pages" do
      page = root.add_page("foo")

      expect(page.parent).to eq(root)
      expect(root.tree.children.map(&:value)).to eq([page.tree.value])
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
      expect(parent.tree.children.map(&:value)).to eq([page.tree.value])
      expect(grandparent.tree.children.map(&:value)).to eq([parent.tree.value])
      expect(root.tree.children.map(&:value)).to eq([grandparent.tree.value])
    end
  end

  describe "#find_in_tree" do
    it "finds exact title matches" do
      page = root.add_page("foo/bar/baz")
      root.add_page("baz")

      expect(root.find_in_tree("foo/bar/baz").value).to eq(page.tree.value)
      expect(root.find_in_tree("foo/bar").value).to eq(page.parent.tree.value)
    end

    it "returns nil if there is no match" do
      root.add_page("foo/bar")

      expect(root.find_in_tree("foo/bar/baz")).to be_nil
    end

    it "returns a partial match" do
      page = root.add_page("foo/bar/baz")

      expect(root.find_in_tree("bar/baz").value).to eq(page.tree.value)
    end

    it "doesn't match if a path component is incomplete" do
      root.add_page("foo/bar/baz")

      expect(root.find_in_tree("ar/baz")).to be_nil
    end

    it "returns the page with the shortest slug if there are multiple partial matches" do
      page = root.add_page("bar/baz")
      root.add_page("foo/bar/baz")

      expect(root.find_in_tree("bar/baz").value).to eq(page.tree.value)
    end

    it "returns the first match if there are multiple partial matches at the same level" do
      page = root.add_page("aa/bar/baz")
      root.add_page("foo/bar/baz")

      expect(root.find_in_tree("aa/bar/baz").value).to eq(page.tree.value)
    end

    it "ignores /index in query strings" do
      page = root.add_page("foo/bar")

      expect(root.find_in_tree("foo/bar/index").value).to eq(page.tree.value)
      expect(root.find_in_tree("foo/index/bar/index").value).to eq(page.tree.value)
      expect(root.find_in_tree("foo/index").value).to eq(page.parent.tree.value)
    end
  end

  describe "#referenced?" do
    it "is true after #mark_referenced is called on a child node" do
      page = root.add_page("foo/bar")
      page.mark_referenced
      expect(page.referenced?("foo/bar")).to eq(true)
      expect(page.referenced?("foo")).to eq(true)
    end
  end

  describe "#prune!" do
    it "does not delete referenced pages" do
      root.add_page("foo/bar").mark_referenced
      root.prune!
      expect(root.find_in_tree("foo/bar")).not_to be_nil
    end

    it "deletes unreferenced pages" do
      root.add_page("foo/bar").mark_referenced
      page = root.add_page("foo/baz")
      expect(page.referenced?("foo/baz")).to eq(false)
      root.prune!
      expect(root.find_in_tree("foo")).not_to be_nil
      expect(root.find_in_tree("foo/bar")).not_to be_nil
      expect(root.find_in_tree("foo/baz")).to be_nil
    end
  end
end
