# frozen_string_literal: true

RSpec.describe Obsidian::Parser do
  EXAMPLE_VAULT = Pathname.new(__dir__).join('../example_vault')

  subject(:parser) { described_class.new(EXAMPLE_VAULT) }

  it "has a version number" do
    expect(Obsidian::Parser::VERSION).not_to be nil
  end

  it "assigns titles and slugs to top level notes" do
    expect(parser.notes).to include(
      an_object_having_attributes(title: 'some links', slug: 'some links')
    )
  end

  it "assigns titles and slugs to nested notes" do
    expect(parser.notes).to include(
      an_object_having_attributes(title: 'cat', slug: 'animals/cat'),
      an_object_having_attributes(title: 'dog', slug: 'animals/dog')
    )
  end

  it "gives notes a last modified time" do
    expect(parser.notes.first.last_modified).to be_an_instance_of(Time)
  end
end
