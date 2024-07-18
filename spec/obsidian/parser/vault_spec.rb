# frozen_string_literal: true

RSpec.describe Obsidian::Vault do
  subject(:vault) { described_class.create_root }

  describe("#add_page") do
    it "relates two pages" do
      page = vault.add_page("foo")

      expect(page.parent).to eq(vault.tree)
      expect(vault.tree.children.map(&:value)).to eq([page.value])
    end

    it "assigns titles and slugs to a top level page" do
      page = vault.add_page("foo")
      meta = page.value

      expect(meta.slug).to eq("foo")
      expect(meta.title).to eq("foo")
    end

    it "assigns titles and slugs to a nested page" do
      page = vault.add_page("foo/bar/baz")
      meta = page.value

      expect(meta.slug).to eq("foo/bar/baz")
      expect(meta.title).to eq("baz")
    end

    it "infers missing directory pages" do
      page = vault.add_page("foo/bar/baz")
      parent = page.parent
      grandparent = parent.parent

      expect(parent.value.slug).to eq("foo/bar")
      expect(grandparent.value.slug).to eq("foo")

      expect(parent.children.map(&:value)).to eq([page.value])
      expect(grandparent.children.map(&:value)).to eq([parent.value])
      expect(vault.tree.children.map(&:value)).to eq([grandparent.value])
    end
  end

  describe "#find_in_tree" do
    it "finds exact title matches" do
      page = vault.add_page("foo/bar/baz")
      vault.add_page("baz")

      expect(vault.find_in_tree("foo/bar/baz").value).to eq(page.value)
      expect(vault.find_in_tree("foo/bar").value).to eq(page.parent.value)
    end

    it "returns nil if there is no match" do
      vault.add_page("foo/bar")

      expect(vault.find_in_tree("foo/bar/baz")).to be_nil
    end

    it "returns a partial match" do
      page = vault.add_page("foo/bar/baz")

      expect(vault.find_in_tree("bar/baz").value).to eq(page.value)
    end

    it "doesn't match if a path component is incomplete" do
      vault.add_page("foo/bar/baz")

      expect(vault.find_in_tree("ar/baz")).to be_nil
    end

    it "returns the page with the shortest slug if there are multiple partial matches" do
      page = vault.add_page("bar/baz")
      vault.add_page("foo/bar/baz")

      expect(vault.find_in_tree("bar/baz").value).to eq(page.value)
    end

    it "returns the first match if there are multiple partial matches at the same level" do
      page = vault.add_page("aa/bar/baz")
      vault.add_page("foo/bar/baz")

      expect(vault.find_in_tree("aa/bar/baz").value).to eq(page.value)
    end

    it "ignores /index in query strings" do
      page = vault.add_page("foo/bar")

      expect(vault.find_in_tree("foo/bar/index").value).to eq(page.value)
      expect(vault.find_in_tree("foo/index/bar/index").value).to eq(page.value)
      expect(vault.find_in_tree("foo/index").value).to eq(page.parent.value)
    end
  end

  describe "#referenced?" do
    it "is true after #mark_referenced is called on a child node" do
      vault.add_page("foo/bar")
      vault.mark_referenced("foo/bar")
      expect(vault.referenced?("foo/bar")).to eq(true)
      expect(vault.referenced?("foo")).to eq(true)
    end
  end

  describe "#prune!" do
    it "does not delete referenced pages" do
      vault.add_page("foo/bar")
      vault.mark_referenced("foo/bar")
      vault.prune!
      expect(vault.find_in_tree("foo/bar")).not_to be_nil
    end

    it "deletes unreferenced pages" do
      vault.add_page("foo/bar")
      vault.mark_referenced("foo/bar")
      vault.add_page("foo/baz")
      expect(vault.referenced?("foo/baz")).to eq(false)
      vault.prune!
      expect(vault.find_in_tree("foo")).not_to be_nil
      expect(vault.find_in_tree("foo/bar")).not_to be_nil
      expect(vault.find_in_tree("foo/baz")).to be_nil
    end
  end

  describe("#collapse") do
    it "preserves subtrees with more than one child" do
      vault.add_page("foo/bar")
      vault.add_page("foo/baz")
      vault.add_page("foo/bar/a")
      vault.add_page("foo/bar/b")

      vault.collapse!

      expect(vault.find_in_tree("foo/bar/a")).not_to be_nil
      expect(vault.find_in_tree("foo/bar/b")).not_to be_nil
      expect(vault.find_in_tree("foo/baz")).not_to be_nil
    end

    it "collapses subtrees with one child" do
      vault.add_page("foo/bar")
      vault.add_page("foo/baz")
      vault.add_page("foo/bar/a")

      vault.collapse!

      expect(vault.find_in_tree("foo/baz")).not_to be_nil
      expect(vault.find_in_tree("foo/bar/a")).to be_nil
      expect(vault.find_in_tree("foo/a")).not_to be_nil
    end
  end
end
