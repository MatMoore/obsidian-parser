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
      return [{}, content]
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

    return {}, content if !complete

    metadata = YAML.safe_load(lines.join)
    rest = []
    loop do
      line = enumerator.next
      rest << line
    end
    [metadata, rest.join]
  rescue YAML::SyntaxError, StopIteration
    [{}, content]
  end
end
