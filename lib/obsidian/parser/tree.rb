# frozen_string_literal: true

module Obsidian
  class Tree
    def initialize(value)
      @value = value
      @children = []
    end

    attr_reader :children
    attr_reader :value

    def inspect
      "Tree(#{value.inspect}) [#{children.length} children]"
    end

    def add_child(value)
      node = Tree.new(value)
      children << node
      node
    end

    def remove_child(value)
      children.delete_if { |node| node.value == value }
    end

    def is_index?
      children.length > 0
    end

    def find(&block)
      walk do |page|
        return page if block.call(page)
      end

      nil
    end

    def walk(&block)
      block.call(self)

      children.each do |page|
        page.walk(&block)
      end
    end
  end
end
