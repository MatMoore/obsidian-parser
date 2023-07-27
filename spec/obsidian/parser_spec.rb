# frozen_string_literal: true

RSpec.describe Obsidian::Parser do
  let(:vault) { Pathname.new(__dir__).join("../example_vault") }

  subject(:parser) { described_class.new(vault) }

  it "has a version number" do
    expect(Obsidian::Parser::VERSION).not_to be nil
  end

  it "assigns titles and slugs to top level notes" do
    expect(parser.notes).to include(
      an_object_having_attributes(title: "some links", slug: "some links")
    )
  end

  it "assigns titles and slugs to nested notes" do
    expect(parser.notes).to include(
      an_object_having_attributes(title: "cat", slug: "animals/cat"),
      an_object_having_attributes(title: "dog", slug: "animals/dog")
    )
  end

  it "assigns titles and slugs to nested directories" do
    expect(parser.index.directories).to include(
      an_object_having_attributes(title: "animals", slug: "animals")
    )
  end

  it "gives notes a last modified time" do
    expect(parser.notes.find { |note| note.title == "cat" }.last_modified).to be_an_instance_of(Time)
  end

  it "generates a table of contents" do
    expect(parser.table_of_contents).to contain_exactly(
      [an_object_having_attributes(title: "animals", slug: "animals"), 0],
      [an_object_having_attributes(title: "cat", slug: "animals/cat"), 1],
      [an_object_having_attributes(title: "dog", slug: "animals/dog"), 1],
      [an_object_having_attributes(title: "red panda", slug: "animals/red panda"), 1],
      [an_object_having_attributes(title: "some links", slug: "some links"), 0]
    )
  end

  it "converts markdown into HTML content" do
    expect(parser.notes.find { |note| note.title == "cat" }.content.generate_html).to eq("<h2 id=\"cats-are-the-best\">Cats are the best</h2>\n\n<p>Meow meow meow</p>\n")
  end

  describe(Obsidian::Note) do
    it "links to its parent" do
      index = Obsidian::Index.new("", "")
      note = index.add_note("slug", "grandparent/parent", Time.now, content: "")

      expect(note.parent.slug).to eq("grandparent/parent")
    end

    it "links to the root if there is no parent" do
      index = Obsidian::Index.new("", "")
      note = index.add_note("slug", "", Time.now, content: "")

      expect(note.parent.slug).to eq("")
    end
  end
end
