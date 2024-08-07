# Obsidian::Parser

A gem to parse notes created with the Obsidian note-taking tool.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add obsidian-parser

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install obsidian-parser

## Usage

Parse the vault with:

```ruby
require 'obsidian/parser'
parser = Obsidian::Parser.new(Pathname.new("/path/to/vault"))
```

The return object allows you to iterate over all pages in the vault.

A page is any note or directory within the vault.

If a directory contains an `index.md`, that will be used as the directory content. Otherwise, the directory will have no content.

```ruby
puts parser.pages
# -> [ Page(title: "", slug: ""), Page(title: "Foo", slug: "Foo"), Page(title: "Bar", slug: "Foo/Bar") ]
```

You can fetch pages by their slug (the relative path, without a leading slash):

```ruby
page = parser.index.find_in_tree("foo/bar")
```

Page objects have titles, slugs, and a callable to fetch their content:

```ruby
page = parser.pages[-1]
title = page.title
markdown = page.content.call
html = page.generate_html
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matmoore/obsidian-parser.

## Resources and similar projects

- [Obsidian link formats](https://help.obsidian.md/Linking+notes+and+files/Internal+links)
- [Obisidian metadata format](https://help.obsidian.md/Editing+and+formatting/Metadata)
- [Obsidian flavored markdown](https://help.obsidian.md/Editing+and+formatting/Obsidian+Flavored+Markdown)
- [Is there a parser/renderer reference spec? (No)](https://forum.obsidian.md/t/is-there-a-parser-renderer-reference-spec/29504/4)
- [Obsidian-Markdown-Parser](https://github.com/danymat/Obsidian-Markdown-Parser) (Python)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
