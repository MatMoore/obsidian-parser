# frozen_string_literal: true

RSpec.describe Obsidian::Parser do
  let(:vault) { Pathname.new(__dir__).join("../example_vault") }

  subject(:parser) { described_class.new(vault) }

  it "has a version number" do
    expect(Obsidian::Parser::VERSION).not_to be nil
  end

  it "assigns titles and slugs to top level notes" do
    expect(parser.pages).to include(
      an_object_having_attributes(title: "some links", slug: "some links")
    )
  end

  it "assigns titles and slugs to nested notes" do
    expect(parser.pages).to include(
      an_object_having_attributes(title: "cat", slug: "animals/cat"),
      an_object_having_attributes(title: "dog", slug: "animals/dog")
    )
  end

  it "assigns titles and slugs to nested directories" do
    expect(parser.index.children).to include(
      an_object_having_attributes(title: "animals", slug: "animals")
    )
  end

  it "gives notes a last modified time" do
    expect(parser.pages.find { |note| note.title == "cat" }.last_modified).to be_an_instance_of(Time)
  end

  it "converts markdown into HTML content" do
    expect(parser.pages.find { |note| note.title == "cat" }.content.generate_html).to eq("<h2 id=\"cats-are-the-best\">Cats are the best</h2>\n\n<p>Meow meow meow</p>\n")
  end

  it "adds index.md content to index pages" do
    animals = parser.index.find_in_tree("animals")

    expect(animals.children.map(&:title)).not_to include("index")
    expect(animals.content&.generate_html).to eq("<p>Animals page</p>\n")
  end

  it "adds index.md content to the root" do
    content = parser.index.content

    expect(content&.generate_html).to eq("<p>Blahhhh</p>\n")
  end
end
