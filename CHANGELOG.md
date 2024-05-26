## [Unreleased]

- Added support for wikilinks that embed files. These are rendered as images or links in the HTML content.
- Added method `Page#generate_html` to replace `Page#content.generate_html`, and removed the `MarkdownDocument` class. `Page#content` is now a callable that returns the markdown content.
- Added `Page#mark_referenced` and `Page#referenced?`
- Added `Page#prune!` method to page objects, to remove non-referenced pages
- Added `Page#parse` method to expose `ParsedMarkdownDocument` objects
- Added `#frontmatter` to `ParsedMarkdownDocument`

## [0.7.0] - 2023-08-03

- Fix wikilinks pointing to slugs with spaces not rendering properly.
- Links created from wikilinks now include a leading slash

## [0.6.1] - 2023-08-03

- Prevent `HtmlRenderer` state being shared across documents

## [0.6.0] - 2023-08-03

- Replace Kramdown with Markly
- Enabled support for Github Flavored Markdown tables and tasklists
- Rename `MarkdownContent` -> `MarkdownDocument`, `ObsidianFlavoredMarkdown` -> `MarkdownParser`

## [0.5.4] - 2023-08-02

- Fix page getting clobbered when wikilinks point to non-existent pages.
- Expand `[[foo/index]]` wiklinks to `[foo](foo)`.

## [0.5.3] - 2023-08-01

- Support non-fully qualified titles when parsing wikilink syntax.
- Autolink raw URLs.

## [0.5.2] - 2023-07-30

- Fix handling of `index.md` at the root level.

## [0.5.0] - 2023-07-30

- Fix ordering of `Page#children` so that index pages come first.
- Fix handling of `index.md` documents so that the slug reflects the directory path.

## [0.4.0] - 2023-07-30

- Unify `Note` and `Index` classes into `Page`. This is a breaking API change. `Parser#notes is replaced by Parse#pages`. Call `Page#is_index?`to distinguish between directory derived pages and documents.
- Remove `Parser#table_of_contents` and `Parser#walk_tree`.
- Add `Page#find_in_tree` to recursively search for a page with a matching slug.
- Rename `Obsidian::MarkdownConverter` to `Obsidian::ParsedMarkdownDocument`

## [0.3.0] - 2023-07-27

- `Note` objects have a `parent` attribute.

## [0.2.0] - 2023-07-24

- `Note` objects have a `content` attribute. Call `content.generate_html` to generate HTML on demand.

## [0.1.0] - 2023-07-10

- Initial release: return a tree of notes
