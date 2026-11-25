# frozen_string_literal: true

require 'ceradoc'

module Ceradoc
  module Plugin
    # Ceradoc plugin that spell-checks AsciiDoc documents via Kotoshu and
    # produces a Word-style YAML/JSON report.
    #
    # Architecture: the plugin never parses raw AsciiDoc itself. It asks Ceradoc
    # for the format-neutral CoreModel tree, walks the tree to extract text
    # spans (with element path + source-line hint), runs each span through
    # Kotoshu, and collects misspellings into a Report.
    module Kotoshu
      autoload :VERSION, 'ceradoc/plugin/kotoshu/version'
      autoload :TextExtractor, 'ceradoc/plugin/kotoshu/text_extractor'
      autoload :ReportError, 'ceradoc/plugin/kotoshu/report_error'
      autoload :Report, 'ceradoc/plugin/kotoshu/report'
      autoload :Checker, 'ceradoc/plugin/kotoshu/checker'
      autoload :Cli, 'ceradoc/plugin/kotoshu/cli'
    end
  end
end
