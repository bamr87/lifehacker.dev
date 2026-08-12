#!/usr/bin/env ruby
# =============================================================================
# lint_artifacts.rb — repo-artifact hygiene the content gate enforces
# -----------------------------------------------------------------------------
# Deterministic checks on the data artifacts the autonomous fleet writes, so a
# generation bug can't quietly land:
#   * backlog ids must be UNIQUE. Two open content PRs can each append (append-
#     only) an item that reuses an id; the second merge then collides or silently
#     clobbers. This is an ERROR — the queue/lease layer keys on the id.
#   * custom-merged data files must have NO DUPLICATE MAPPING KEYS. Any file
#     given a `merge=` driver in .gitattributes trades conflicts for an
#     automatic resolution, and an automatic resolution can stack two values of
#     the SAME key — `published: a` and `published: b` as two lines on one item.
#     Psych keeps the last silently, so Jekyll builds green and the damage only
#     surfaces in a strict parser downstream. This is an ERROR.
# Stdlib only. Run: ruby scripts/ci/lint_artifacts.rb
# =============================================================================
require_relative '_lib'

findings = []

# --- Duplicate mapping keys in custom-merged data files ----------------------
# Scope comes from .gitattributes rather than a hardcoded list: whatever the
# fleet opts into a `merge=` driver is exactly what can grow a duplicate key.
# Match the ATTRIBUTE, not one driver name — this used to test for the literal
# `merge=union`, so swapping `_data/backlog.yml` to the safer `merge=backlog`
# driver would have silently emptied this list and retired the guard that caught
# the splice in the first place.
gitattributes = File.join(LH::ROOT, '.gitattributes')
union_globs = File.exist?(gitattributes) ? LH.read(gitattributes).lines.filter_map { |line|
  next if line.lstrip.start_with?('#')
  pattern, *attrs = line.split
  pattern if pattern && attrs.any? { |a| a.start_with?('merge=') }
} : []

union_globs.flat_map { |glob| Dir.glob(File.join(LH::ROOT, glob)) }
           .select { |path| path.end_with?('.yml', '.yaml') }
           .uniq.sort.each do |path|
  begin
    stream = YAML.parse_stream(LH.read(path))
  rescue Psych::SyntaxError => e
    findings << LH.finding(check_id: 'artifacts', severity: 'error',
                           rule: 'unparseable-data-file', file: LH.rel(path),
                           evidence: "YAML will not parse: #{e.message}")
    next
  end

  # Psych::Nodes::Node#each walks the whole tree; a mapping's children alternate
  # key, value, so each_slice(2) reads the keys with their source lines intact.
  stream.each do |node|
    next unless node.is_a?(Psych::Nodes::Mapping)

    seen = {}
    node.children.each_slice(2) do |key, _value|
      next unless key.is_a?(Psych::Nodes::Scalar)
      if seen.key?(key.value)
        findings << LH.finding(check_id: 'artifacts', severity: 'error',
                               rule: 'duplicate-data-key', file: LH.rel(path),
                               line: key.start_line + 1,
                               evidence: "key `#{key.value}` is set twice in the same mapping " \
                                         "(first at line #{seen[key.value]}) — a merge driver " \
                                         'stacked two values of one key; Psych keeps the LAST ' \
                                         'silently, strict parsers reject the file')
      else
        seen[key.value] = key.start_line + 1
      end
    end
  end
end

# --- Backlog id uniqueness ---------------------------------------------------
bpath = File.join(LH::ROOT, '_data', 'backlog.yml')
if File.exist?(bpath)
  data  = (LH.yload(LH.read(bpath)) rescue {}) || {}
  items = ((data.is_a?(Hash) ? data['backlog'] : nil) rescue []) || []
  ids   = items.map { |i| i.is_a?(Hash) ? i['id'].to_s : '' }.reject(&:empty?)
  ids.group_by(&:itself).select { |_, v| v.size > 1 }.each_key do |id|
    findings << LH.finding(check_id: 'artifacts', severity: 'error',
                           rule: 'duplicate-backlog-id', file: '_data/backlog.yml',
                           evidence: "backlog id `#{id}` appears #{ids.count(id)}x — ids must be unique (the second append collides on merge)")
  end
end

errs = LH.write('artifacts', findings)
exit(errs.zero? ? 0 : 1)
