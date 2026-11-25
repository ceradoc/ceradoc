# frozen_string_literal: true

require 'ceradoc'
require_relative 'ceradoc/mirror'

# Side-effect: registers format modules with Ceradoc registry.
# These must use require (not autoload) because they have load-time side effects.
require_relative 'ceradoc/mirror/mirror_json_format'
require_relative 'ceradoc/mirror/mirror_yaml_format'

# Ensure Ceradoc error classes are loaded (autoloaded via Ceradoc::Error).
Ceradoc::Error
