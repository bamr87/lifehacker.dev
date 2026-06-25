# =============================================================================
# scripts/fleet/plan.rb — the pure dispatch plan (observe-tally + decide + pick)
# -----------------------------------------------------------------------------
# Separates the dispatcher's DECISION (pure, testable) from its IO (gh counts,
# git leases, agent spawns). dispatch.rb gathers the observations and then leases
# what this returns; the E2E simulation calls this directly with synthetic inputs
# and asserts. Both share one decision path, so they cannot drift.
# =============================================================================
require_relative 'policy'

module Fleet
  module Plan
    module_function

    # queue:   the _data/health/queue.json array
    # backlog: the _data/backlog.yml "backlog" array
    # open_prs: integer (the dispatcher counts these via gh)
    # caps:    parsed _data/fleet/budget.yml
    # fresh:   is the queue trustworthy (present + recently regenerated)? When
    #          false the absence of data must NOT read as "safe to grow" — we
    #          fail safe and dispatch nothing. dispatch.rb decides freshness.
    # -> { obs:, decision:, dispatched: [ {role, target, desc}, ... ] }
    def compute(queue:, backlog:, open_prs:, caps:, fresh: true)
      unless fresh
        return { obs: { open_prs: open_prs, fresh: false },
                 decision: { mode: 'stale', slots: { grow: 0, fix: 0 }, available_slots: 0,
                             reason: 'queue missing or stale — fail-safe: dispatching nothing rather than growing blind' },
                 dispatched: [] }
      end

      sev1 = queue.count { |i| i['severity'] == 'sev1' }
      sev2 = queue.count { |i| i['severity'] == 'sev2' }
      # Field-Note candidates are content work ("write the Field Note"), not bug
      # fixes — never lease them to fleet-bugfix. Key the fixable set off type.
      fixable  = queue.select { |i| i['route'] == 'local' &&
                                    %w[sev1 sev2 sev3].include?(i['severity']) &&
                                    i['type'] != 'type/field-note-candidate' }
                      .sort_by { |i| -i['score'].to_f }
      # Growable = todo, EXCEPT ops/admin items. A backlog item can carry a task a
      # content agent must NOT try to "generate" (kind: ops — e.g. "enable branch
      # protection"); those stay visible as todo for a human but the fleet skips them.
      growable = backlog.select { |b| b['status'].to_s == 'todo' && b['kind'].to_s != 'ops' }

      obs = { sev1: sev1, sev2: sev2, open_prs: open_prs,
              growth_available: growable.size, fix_available: fixable.size }
      decision = Fleet::Policy.decide(obs, caps)

      dispatched = []
      fixable.first(decision[:slots][:fix]).each do |i|
        dispatched << { role: 'fleet-bugfix', target: i['fingerprint'], desc: i['title'].to_s }
      end
      growable.first(decision[:slots][:grow]).each do |b|
        dispatched << { role: 'grow-lifehacker', target: b['id'].to_s, desc: b['title'].to_s }
      end

      { obs: obs, decision: decision, dispatched: dispatched }
    end
  end
end
