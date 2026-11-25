# frozen_string_literal: true

require_relative 'lib/coridoc/asciidoc/version'

Gem::Specification.new do |spec|
  spec.name = 'coridoc-adoc'
  spec.version = Coridoc::AsciiDoc::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'AsciiDoc support for Coridoc'
  spec.description = 'AsciiDoc Document Model, Parser, and Serializer for the ' \
                     'Coridoc document transformation framework. Provides ' \
                     'bidirectional transformation between AsciiDoc and CoreModel.'
  spec.homepage = 'https://github.com/coridoc/coridoc'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f == __FILE__ || f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'coridoc', '~> 3.0'
  spec.add_dependency 'lutaml-model', '~> 0.8.0'
  spec.add_dependency 'parsanol', '~> 1.3.123'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
