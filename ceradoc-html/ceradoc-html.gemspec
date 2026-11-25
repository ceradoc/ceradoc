# frozen_string_literal: true

require_relative 'lib/ceradoc/html/version'

Gem::Specification.new do |spec|
  spec.name = 'ceradoc-html'
  spec.version = Ceradoc::Html::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'HTML input/output converters for Ceradoc'
  spec.description = 'Provides HTML to AsciiDoc conversion and AsciiDoc to HTML ' \
                     'rendering with both classic and modern Vue.js SPA themes'
  spec.homepage = 'https://github.com/ceradoc/ceradoc'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ceradoc/ceradoc'
  spec.metadata['changelog_uri'] = 'https://github.com/ceradoc/ceradoc/releases'

  # Include all lib/ files
  spec.files = Dir.chdir(__dir__) do
    Dir['lib/**/*.rb'] + ['LICENSE.txt']
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'ceradoc', '~> 3.0'
  spec.add_dependency 'ceradoc-adoc', '~> 2.0'
  spec.add_dependency 'leptris', '~> 1.9.222'
  spec.add_dependency 'marcel', '~> 1.0'
  spec.add_dependency 'plurimath', '~> 0.11'

  # Development dependencies
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'simplecov'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
