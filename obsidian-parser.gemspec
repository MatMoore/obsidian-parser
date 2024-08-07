# frozen_string_literal: true

require_relative "lib/obsidian/parser/version"

Gem::Specification.new do |spec|
  spec.name = "obsidian-parser"
  spec.version = Obsidian::Parser::VERSION
  spec.authors = ["Mat Moore"]
  spec.email = ["matmoore@users.noreply.github.com"]

  spec.summary = "Parse notes created with the Obsidian note-taking tool."
  # spec.description = "TODO: Write a longer description or delete this line."

  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["source_code_uri"] = "https://github.com/matmoore/obsidian-parser"
  spec.metadata["changelog_uri"] = "https://github.com/matmoore/obsidian-parser/tree/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "markly", "~> 0.7.0"
  spec.add_dependency "marcel", "~> 0.3.1"
  spec.add_dependency "tilt", "~> 2.0", ">= 2.0.8"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
