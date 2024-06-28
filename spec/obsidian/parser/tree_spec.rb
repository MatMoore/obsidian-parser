# frozen_string_literal: true

RSpec.describe Obsidian::Tree do
  subject(:root) { described_class.new(:root) }

  describe("creating, retrieving, and removing nodes") do
    before do
      foo = root.add_child("a", :foo)
      foo.add_child("a", :bar)
      foo.add_child("b", :baz)
    end

    it "can find a node from the root" do
      a = root.find { |node| node.value == :baz }

      expect(a&.value).to eq(:baz)
    end

    it "can list the children of a node" do
      foo = root.children.first

      expect(root.children.map(&:value)).to eq([:foo])
      expect(foo.children.map(&:value)).to eq([:bar, :baz])
    end

    it "can remove nodes" do
      root.remove_child("a")
      expect(root.children).to be_empty
    end

    it "can tell if a node is non-terminal" do
      foo = root.children.first
      bar = foo.children.first
      expect(root.is_index?).to eq(true)
      expect(foo.is_index?).to eq(true)
      expect(bar.is_index?).to eq(false)
    end
  end
end
