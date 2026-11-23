# frozen_string_literal: true

require 'coridoc'
require_relative 'coridoc/mirror'

# Side-effect: registers format modules with Coridoc registry.
# These must use require (not autoload) because they have load-time side effects.
require_relative 'coridoc/mirror/mirror_json_format'
require_relative 'coridoc/mirror/mirror_yaml_format'

# Ensure Coridoc error classes are loaded (autoloaded via Coridoc::Error).
Coridoc::Error
