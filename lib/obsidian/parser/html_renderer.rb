class HtmlRenderer < Markly::Renderer::HTML
  def header(node)
    block do
      out("<h", node.header_level, " id=\"", header_id(node), "\">",
        :children, "</h", node.header_level, ">")
    end
  end

  private

  def header_id(node)
    # Taken from Kramdown
    # https://github.com/gettalong/kramdown/blob/bd678ecb59f70778fdb3b08bdcd39e2ab7379b45/lib/kramdown/converter/base.rb
    gen_id = extract_text(node).gsub(/^[^a-zA-Z]+/, "")
    gen_id.tr!("^a-zA-Z0-9 -", "")
    gen_id.tr!(" ", "-")
    gen_id.downcase!

    gen_id = "section" if gen_id.empty?

    @used_ids ||= {}
    if @used_ids.key?(gen_id)
      gen_id += "-#{@used_ids[gen_id] += 1}"
    else
      @used_ids[gen_id] = 0
    end

    gen_id
  end

  def extract_text(node)
    node.each do |subnode|
      if subnode.type == :text
        return subnode.string_content
      end
    end

    ""
  end
end
