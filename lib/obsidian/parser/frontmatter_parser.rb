require "yaml"

class Obsidian::MarkdownParser::FrontMatterParser
  # Look for frontmatter delimited by '---' lines
  # and try to interpret it as yaml.
  # If it is valid YAML, then denotes properties.
  # https://help.obsidian.md/Editing+and+formatting/Properties#Property+format
  def parse(content)
    enumerator = content.each_line
    first_line = enumerator.next
    complete = false

    if first_line.chomp != "---"
      puts "bye"
      return {}
    end

    lines = []
    loop do
      line = enumerator.next
      if line.chomp == "---"
        complete = true
        break
      end
      lines << line
    end

    puts lines
    puts complete

    complete ? YAML.safe_load(lines.join) : {}
  rescue YAML::SyntaxError, StopIteration
    {}
  end
end
