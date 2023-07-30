## [Unreleased]

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
