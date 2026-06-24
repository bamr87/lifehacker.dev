# =============================================================================
# scripts/fleet/policy.rb — the deterministic load-balancing policy
# -----------------------------------------------------------------------------
# Pure function (no IO, no gh, no git) so it is fully unit-testable and its
# decisions are reproducible and auditable. The dispatcher does the observing
# and acting; THIS only does the math: given the site's health and the caps,
# how many grower vs fixer slots run this cycle?
#
# The load-balancing primitive is MAX_OPEN_PRS: the dispatcher never launches
# work that would leave more than that many PRs awaiting the single human
# reviewer, so throughput is clamped to review speed by design — adding agents
# drains the queue faster but can never flood the gate.
# =============================================================================
module Fleet
  module Policy
    module_function

    # obs:  { sev1:, sev2:, open_prs:, growth_available:, fix_available: }
    # caps: parsed _data/fleet/budget.yml ("caps" + "split")
    # -> { mode:, slots: {grow:, fix:}, available_slots:, reason: }
    def decide(obs, caps)
      max_conc = caps.dig('caps', 'max_concurrency').to_i
      max_prs  = caps.dig('caps', 'max_open_prs').to_i
      open_prs = obs[:open_prs].to_i

      # Backpressure first: at/over the open-PR cap, launch nothing — the human
      # is the bottleneck and that is by design.
      headroom = max_prs - open_prs
      if headroom <= 0
        return { mode: 'backpressure', slots: { grow: 0, fix: 0 }, available_slots: 0,
                 reason: "#{open_prs}/#{max_prs} open PRs — at the cap; draining the human queue, launching nothing" }
      end

      available = [max_conc, headroom].min

      mode =
        if obs[:sev1].to_i > 0 then 'sev1'
        elsif obs[:sev2].to_i > 0 then 'sev2'
        else 'clean'
        end

      rule = caps.dig('split', mode) || {}
      grow_want = resolve(rule['grow'], available)
      fix_want  = resolve(rule['fix'],  available)

      # First-come for fix in 'all'/'rest' modes, then growth fills the rest.
      grow = [grow_want, obs[:growth_available].to_i, available].min
      fix  = [fix_want,  obs[:fix_available].to_i, available - grow].min
      grow = [grow, available - fix].min if (grow + fix) > available

      reason =
        case mode
        when 'sev1' then "#{obs[:sev1]} sev1 open — growth FROZEN, all slots fixing"
        when 'sev2' then "#{obs[:sev2]} sev2 open — one grower, rest maintaining"
        else "site clean — mostly growing"
        end
      reason += "; capped to #{available} slot(s) (#{max_conc} concurrency, #{headroom} PR headroom)"

      { mode: mode, slots: { grow: grow, fix: fix }, available_slots: available, reason: reason }
    end

    # "all" -> every available slot; "rest" -> sentinel meaning "after growth";
    # an integer -> itself.
    def resolve(val, available)
      case val
      when 'all'  then available
      when 'rest' then available
      when nil    then 0
      else val.to_i
      end
    end
  end
end
