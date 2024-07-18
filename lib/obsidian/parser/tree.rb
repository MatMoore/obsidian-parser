# frozen_string_literal: true

module Obsidian
  class Tree
    def initialize(value, parent: nil, order_by: nil)
      @value = value
      @children = {}
      @parent = parent
      @order_by = order_by
    end

    attr_accessor :value
    attr_reader :parent

    def children
      if @order_by
        @children.values.sort_by(&@order_by)
      else
        @children.values
      end
    end

    def anscestors
      return [] if @parent.nil?

      [parent] + parent.anscestors
    end

    def inspect
      "Tree(#{value.inspect}) [#{children.length} children]"
    end

    def add_child(key, value)
      node = Tree.new(value, parent: self)
      add_child_node(key, node)
    end

    def add_child_node(key, node)
      @children[key] = node
    end

    def get_child(key)
      @children[key]
    end

    def child_exists(key)
      @children.include?(key)
    end

    def add_child_unless_exists(key, value)
      child = @children[key]
      return child unless child.nil?
      add_child(key, value)
    end

    def remove_child(key)
      @children.delete(key)
    end

    def is_index?
      @children.length > 0
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

    def remove_all(&block)
      @children.delete_if do |key, node|
        block.call(node.value)
      end

      children.each do |child|
        child.remove_all(&block)
      end
    end
  end
end
