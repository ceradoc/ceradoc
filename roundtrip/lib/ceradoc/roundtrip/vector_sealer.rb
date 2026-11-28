# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'yaml'

module Ceradoc
  module Roundtrip
    # Seals the parity vector set (docs/_references/parity-vectors.adoc).
    #
    # For every corpus case that round-trips today (the corpus minus
    # +known_failures.yml+, plus Vector::Adversarial) and every layer
    # that supports the case's format, the sealer parses the input and
    # seals the layer model's lutaml-generated serializations:
    #
    # - bytes are generated twice and must be identical (in-run
    #   determinism guard);
    # - the generated loader must reload the bytes; the structural
    #   result is either a verified vector or an entry in
    #   +loader_gaps.yml+;
    # - a serialization that raises is an entry in +producer_gaps.yml+,
    #   not a silent omission (a layer left with no sealable format
    #   contributes no vector at all).
    #
    # Then the whole set is checksum-manifested into
    # +roundtrip/vectors/manifest.yml+. Re-sealing rewrites everything
    # deterministically; files that the previous manifest proves were
    # generated (checksum matches) and are no longer produced are
    # pruned. Hand-edited files are left untouched and reported.
    class VectorSealer
      Gap = Struct.new(:id, :reason, keyword_init: true)

      def self.seal
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        report = new.seal
        seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - time
        puts(format('sealed %<vectors>d vectors (%<files>d files) in %<seconds>.1fs',
                    vectors: report[:vectors], files: report[:files], seconds:))
        puts "  #{report[:counts].sort.map { |k, v| "#{k}: #{v}" }.join('  ')}"
        puts "  loader gaps: #{report[:loader_gaps].size}   producer gaps: #{report[:producer_gaps].size}"
        puts "  loader gaps #{report[:loader_delta]}   producer gaps #{report[:producer_delta]}"
        report[:pruned].each { |path| puts "  pruned stale #{path}" }
        report[:untracked].each { |path| puts "  WARNING untracked file left in place: #{path}" }
        report
      end

      # The vector corpus: round-trip corpus minus known failures plus
      # the adversarial set, sorted. With +check_roundtrip+ the list is
      # first proven stable by the round-trip Checker — vectors pin
      # parity, not known bugs — raising on any unstable case.
      def self.curated_cases(check_roundtrip: false)
        cases = (Corpus.cases.reject { |c| KnownFailures.new.include?(c.id) } +
                 Vector::Adversarial.all).sort_by(&:id)
        return cases unless check_roundtrip

        checker = Checker.new
        unstable = cases.filter_map do |kase|
          failure = checker.call(kase)
          "#{kase.id}: #{failure&.stage}" if failure
        end
        return cases if unstable.empty?

        raise ArgumentError, "vector corpus must round-trip; unstable cases:\n#{unstable.join("\n")}"
      end

      def seal
        results = seal_all(self.class.curated_cases(check_roundtrip: true))
        write_tree(results)
        write_gaps(results)
        write_manifest(results)
        prune_stale(results)
        { vectors: results[:vectors].size, files: results[:paths].size,
          counts: results[:counts], loader_gaps: results[:loader_gaps],
          producer_gaps: results[:producer_gaps], loader_delta: results[:loader_delta],
          producer_delta: results[:producer_delta], pruned: results[:pruned],
          untracked: results[:untracked] }
      end

      private

      def seal_all(cases)
        vectors = []
        producer_gaps = []
        loader_gaps = []
        cases.each do |kase|
          Vector::Capabilities.layers_for(kase.format).each do |layer|
            vector = seal_vector(kase, layer, producer_gaps, loader_gaps)
            vectors << vector if vector
          end
        end
        { vectors: vectors, producer_gaps: producer_gaps, loader_gaps: loader_gaps,
          counts: vectors.group_by { |v| "#{v.layer}/#{v.format}" }.transform_values(&:size) }
      end

      # Parse once per (case, layer); seal each serialization format.
      # Returns nil when every format is a producer gap.
      def seal_vector(kase, layer, producer_gaps, loader_gaps)
        lane = Vector::Capabilities.ruby_lane(layer, kase.format)
        model = lane.parse.call(kase.text)
        sealed = Vector::Capabilities::SEALED_FORMATS.filter_map do |fmt|
          bytes = generated_bytes(lane, fmt, kase, layer, producer_gaps)
          next if bytes.nil?

          verify_loader(lane, fmt, model, kase, layer, loader_gaps)
          [fmt, bytes]
        end
        return nil if sealed.empty?

        Vector.new("#{kase.id}@#{layer}", layer, kase.format, kase.text, sealed.to_h)
      end

      # In-run determinism: two generations must agree byte for byte.
      def generated_bytes(lane, fmt, kase, layer, producer_gaps)
        first = lane.serializers.fetch(fmt).call(lane.parse.call(kase.text))
        second = lane.serializers.fetch(fmt).call(lane.parse.call(kase.text))
        if first != second
          raise ArgumentError, "nondeterministic serialization for #{kase.id}@#{layer}[#{fmt}]"
        end

        first
      rescue StandardError => e
        producer_gaps << Gap.new(id: gap_id(layer, fmt, kase),
                                 reason: "#{e.class}: #{e.message.lines.first&.chomp}")
        nil
      end

      def verify_loader(lane, fmt, model, kase, layer, loader_gaps)
        reloaded = lane.loaders.fetch(fmt).call(lane.serializers.fetch(fmt).call(model))
        diff = Projection.first_difference(Projection.of(model), Projection.of(reloaded))
        return unless diff

        loader_gaps << Gap.new(id: gap_id(layer, fmt, kase),
                               reason: "generated loader diverges at #{diff[0]}")
      rescue StandardError => e
        # a loader that RAISES is a gap of the same kind as one that
        # diverges — the serialization cannot round-trip yet
        loader_gaps << Gap.new(id: gap_id(layer, fmt, kase),
                               reason: "#{e.class}: #{e.message.lines.first&.chomp}")
      end

      def gap_id(layer, fmt, kase) = "#{kase.id}@#{layer}:#{fmt}"

      # --- writing ---

      def write_tree(results)
        paths = []
        results[:vectors].each do |vector|
          write_file(vector.input_path, vector.input, paths)
          vector.sealed.each { |fmt, bytes| write_file(vector.sealed_paths.fetch(fmt.to_s), bytes, paths) }
        end
        results[:paths] = paths
      end

      def write_file(relpath, content, paths)
        FileUtils.mkdir_p(File.dirname(Vector::Store.join(relpath)))
        File.binwrite(Vector::Store.join(relpath), content)
        paths << relpath
      end

      def write_gaps(results)
        loader = results[:loader_gaps].to_h { |gap| [gap.id, gap.reason] }
        producer = results[:producer_gaps].to_h { |gap| [gap.id, gap.reason] }
        results[:loader_delta] = gap_delta(Vector::Gaps.load(Vector::Store::LOADER_GAPS), loader)
        results[:producer_delta] = gap_delta(Vector::Gaps.load(Vector::Store::PRODUCER_GAPS), producer)
        Vector::Gaps.write(loader, Vector::Store::LOADER_GAPS)
        Vector::Gaps.write(producer, Vector::Store::PRODUCER_GAPS)
      end

      # @return [String] a one-line added/cleared summary for the report
      def gap_delta(previous, current)
        added = (current.keys - previous.ids).sort
        cleared = (previous.ids - current.keys).sort
        parts = []
        parts << "added #{added.join(', ')}" if added.any?
        parts << "cleared #{cleared.join(', ')}" if cleared.any?
        parts.empty? ? 'unchanged' : parts.join(' / ')
      end

      def write_manifest(results)
        entries = results[:vectors].to_h do |vector|
          [vector.id, vector_manifest_entry(vector)]
        end
        counts = results[:counts].merge('total' => results[:vectors].size)
        manifest = {
          'generated_by' => 'rake roundtrip:vectors:seal',
          'schema' => Vector::Store::SCHEMA,
          'counts' => counts.sort.to_h,
          'entries' => entries.sort.to_h
        }
        File.write(Vector::Store::MANIFEST, YAML.dump(manifest))
        results[:paths] << Vector::Store::MANIFEST.delete_prefix("#{Vector::Store::DIR}/")
      end

      def vector_manifest_entry(vector)
        entry = {
          'layer' => vector.layer,
          'format' => vector.format.to_s,
          'input' => vector.input_path,
          'sealed' => vector.sealed_paths,
          'sha256' => { 'input' => hash_of(vector.input_path) }
        }
        vector.sealed_paths.each { |fmt, path| entry['sha256'][fmt] = hash_of(path) }
        entry
      end

      def hash_of(relpath) = ::Digest::SHA256.file(Vector::Store.join(relpath)).hexdigest

      # Remove files the previous manifest proves were generated
      # (checksum matches) and that this seal no longer produces.
      # Anything else under the vectors directory is left untouched.
      def prune_stale(results)
        previous_paths = previous_manifest_paths
        current = results[:paths] + gap_files
        pruned = (previous_paths.keys - current).filter_map do |path|
          full = Vector::Store.join(path)
          next unless ::Digest::SHA256.file(full).hexdigest == previous_paths.fetch(path)

          File.delete(full)
          path
        end
        listed = Dir.glob('**/*', base: Vector::Store::DIR).select { |p| File.file?(Vector::Store.join(p)) }
        { pruned: pruned, untracked: (listed - current - pruned).sort }
      end

      def previous_manifest_paths
        YAML.safe_load_file(Vector::Store::MANIFEST).fetch('entries').flat_map do |_id, entry|
          Vector::Store.paths_and_hashes(entry)
        end.to_h
      rescue Errno::ENOENT
        {}
      end

      def gap_files
        [Vector::Store::LOADER_GAPS, Vector::Store::PRODUCER_GAPS]
          .map { |p| p.delete_prefix("#{Vector::Store::DIR}/") }
      end
    end
  end
end
