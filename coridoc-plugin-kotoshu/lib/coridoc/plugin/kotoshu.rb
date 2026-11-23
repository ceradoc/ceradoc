# frozen_string_literal: true

require 'coridoc'

module Coridoc
  module Plugin
    # Coridoc plugin that spell-checks AsciiDoc documents via Kotoshu and
    # produces a Word-style YAML/JSON report.
    #
    # Architecture: the plugin never parses raw AsciiDoc itself. It asks Coridoc
    # for the format-neutral CoreModel tree, walks the tree to extract text
    # spans (with element path + source-line hint), runs each span through
    # Kotoshu, and collects misspellings into a Report.
    module Kotoshu
      autoload :VERSION, 'coridoc/plugin/kotoshu/version'
      autoload :TextExtractor, 'coridoc/plugin/kotoshu/text_extractor'
      autoload :ReportError, 'coridoc/plugin/kotoshu/report_error'
      autoload :Report, 'coridoc/plugin/kotoshu/report'
      autoload :Checker, 'coridoc/plugin/kotoshu/checker'
      autoload :Cli, 'coridoc/plugin/kotoshu/cli'
    end
  end
end
