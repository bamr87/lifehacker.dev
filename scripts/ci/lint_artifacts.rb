#!/usr/bin/env ruby
# =============================================================================
# lint_artifacts.rb — repo-artifact hygiene the content gate enforces
# -----------------------------------------------------------------------------
# Deterministic checks on the data artifacts the autonomous fleet writes, so a
# generation bug can't quietly land:
#   * backlog ids must be UNIQUE. Two open content PRs can each append (append-
#     only) an item that reuses an id; the second merge then collides or silently
#     clobbers. This is an ERROR — the queue/lease layer keys on the id.
# Stdlib only. Run: ruby scripts/ci/lint_artifacts.rb
# =============================================================================
require_relative '_lib'

findings = []

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
