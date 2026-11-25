# frozen_string_literal: true

require_relative 'lib/ceradoc/markdown/version'

Gem::Specification.new do |spec|
  spec.name = 'ceradoc-markdown'
  spec.version = Ceradoc::Markdown::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'Markdown document model, parser, and serializer for Ceradoc'
  spec.description = 'Provides Markdown parsing and serialization capabilities for Ceradoc. ' \
                     'Includes the Markdown Document Model, a CommonMark-compliant Parsanol-based ' \
                     'parser, and round-trip capable serializer.'
  spec.homepage = 'https://github.com/ceradoc/ceradoc'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ceradoc/ceradoc'
  spec.metadata['changelog_uri'] = 'https://github.com/ceradoc/ceradoc/releases'

  # Include all lib/ files and the frozen parser grammar (the parser
  # loads grammar/ceradoc-markdown.artifact.json relative to the gem
  # root at runtime)
  spec.files = Dir.chdir(__dir__) do
    Dir['lib/**/*.rb', 'schemas/*.yml', 'grammar/**/*'] + ['LICENSE.txt']
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core dependencies
  spec.add_dependency 'ceradoc', '~> 3.0'
  spec.add_dependency 'lutaml-model', '~> 0.8.0'
  # Span the line like ceradoc-adoc (>= 1.3.123, < 2): the ~> 1.3 pin has
  # no overlap with the expressir >= 2.4.75 chain (parsanol ~> 1.5.1),
  # so mixed bundles carrying both cannot resolve
  spec.add_dependency 'parsanol', '>= 1.3.123', '< 2'

  # Development dependencies
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'simplecov'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
