# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'yaml'

module Ceradoc
  module Roundtrip
    class Vector
      # Disk home of the sealed vector set: the committed fixture data
      # under +roundtrip/vectors/+ and its checksum manifest.
      #
      # Layout, all paths relative to the vectors directory:
      #
      #   manifest.yml                     checksum manifest (generated)
      #   loader_gaps.yml                  generated-loader ratchet (generated)
      #   producer_gaps.yml                generated-serializer ratchet (generated)
      #   <format>/<layer>/<case>.input    the input text
      #   <format>/<layer>/<case>.json     sealed serialization
      #   <format>/<layer>/<case>.yaml     sealed serialization
      #
      # The directory is sealed data: everything in it is written by
      # the sealer and checksummed by the manifest. Hand edits are
      # caught by `roundtrip:vectors:verify`.
      class Store
        DIR = File.join(Roundtrip::ROOT, 'vectors')
        MANIFEST = File.join(DIR, 'manifest.yml')
        LOADER_GAPS = File.join(DIR, 'loader_gaps.yml')
        PRODUCER_GAPS = File.join(DIR, 'producer_gaps.yml')

        SCHEMA = 1

        class << self
          # @return [Store] every vector listed by the committed manifest
          def load
            manifest = YAML.safe_load_file(MANIFEST)
            vectors = manifest.fetch('entries').filter_map do |id, entry|
              layer = entry.fetch('layer')
              next unless Capabilities.layer?(layer)

              sealed = entry.fetch('sealed').to_h do |fmt, path|
                [fmt.to_sym, read(path)]
              end
              Vector.new(id, layer, entry.fetch('format').to_sym, read(entry.fetch('input')), sealed)
            end
            new(vectors, manifest)
          end

          def read(path) = File.binread(join(path))

          def join(path) = File.join(DIR, path)

          # Manifest entry => [(relative path, expected sha256), ...]
          def paths_and_hashes(entry)
            entry.fetch('sha256').map do |kind, hash|
              path = kind == 'input' ? entry.fetch('input') : entry.fetch('sealed').fetch(kind)
              [path, hash]
            end
          end
        end

        attr_reader :vectors

        def initialize(vectors, manifest)
          @vectors = vectors
          @manifest = manifest
        end

        # @return [Array<String>] manifest-listed files whose bytes no
        #   longer match the recorded checksum
        def checksum_mismatches
          @manifest.fetch('entries').flat_map do |_id, entry|
            self.class.paths_and_hashes(entry).filter_map do |path, expected|
              actual = ::Digest::SHA256.file(self.class.join(path)).hexdigest
              "manifest checksum mismatch for #{path}" if actual != expected
            end
          end
        end
      end
    end
  end
end
