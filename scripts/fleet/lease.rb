# =============================================================================
# scripts/fleet/lease.rb — collision-free work claiming with no server
# -----------------------------------------------------------------------------
# Two agents must never grab the same queue item. The atomic primitive is git
# ref creation: `git update-ref refs/lease/<id> HEAD ''` (empty old-value =
# "create only if absent") succeeds for exactly one caller and fails for the
# rest — a compare-and-swap with no database. A committed _data/fleet/leases.yml
# carries the human-readable record + claim time so leases survive across cycles
# and a crashed agent's lease can be reclaimed after a TTL.
#
# (The dispatch workflow also runs under concurrency:group=fleet-dispatch, so
# only one dispatcher is ever live; the ref CAS guards within a cycle and the
# YAML guards across them.)
# =============================================================================
require 'time'
require_relative '../ci/_lib'

module Fleet
  module Lease
    FILE = File.join(LH::ROOT, '_data', 'fleet', 'leases.yml')

    module_function

    def ref(id)
      "refs/lease/#{id.to_s.gsub(/[^a-zA-Z0-9._-]/, '-')}"
    end

    def load
      return [] unless File.exist?(FILE)
      (LH.yload(LH.read(FILE)) || []).select { |h| h.is_a?(Hash) }
    end

    HEADER = "# Active work leases (managed by scripts/fleet/lease.rb). Empty = nothing claimed.\n" \
             "# Each entry: { id, role, ref, claimed_at }. The git ref refs/lease/<id> is the\n" \
             "# atomic guard; this file is the human-readable record + TTL clock.\n".freeze

    def save(leases)
      File.write(FILE, HEADER + leases.to_yaml)
    end

    def active(ttl_minutes = nil)
      ls = load
      return ls unless ttl_minutes
      cutoff = Time.now.utc - ttl_minutes * 60
      ls.select { |l| (Time.parse(l['claimed_at']) rescue Time.at(0)) > cutoff }
    end

    def git(args)
      out = `git #{args} 2>&1`
      [out.strip, $?.success?]
    end

    # Atomically claim id for role. Returns true if this caller won it.
    def claim(id, role, ttl_minutes = 60)
      reclaim_stale(ttl_minutes)
      return false if load.any? { |l| l['id'] == id.to_s }   # already recorded
      _out, ok = git("update-ref #{ref(id)} HEAD ''")        # CAS: create-only
      return false unless ok                                  # lost the race
      begin
        leases = load
        leases << { 'id' => id.to_s, 'role' => role.to_s,
                    'ref' => ref(id), 'claimed_at' => Time.now.utc.iso8601 }
        save(leases)
      rescue StandardError
        # The CAS won but recording it failed. Roll the ref back so the item is
        # NOT orphaned: reclaim_stale only ever sees YAML entries, so an
        # unrecorded ref would block every future claim forever (the CAS keeps
        # failing) and never be cleaned. Better to drop the claim and retry.
        git("update-ref -d #{ref(id)}")
        raise
      end
      true
    end

    def release(id)
      # Delete the ref FIRST (the authoritative guard), then update the record.
      # If the save fails here the ref is already gone and the stale YAML entry
      # self-heals at the TTL — it can never strand the item the way an orphaned
      # ref would.
      git("update-ref -d #{ref(id)}")
      save(load.reject { |l| l['id'] == id.to_s })
    end

    # Drop leases older than the TTL (a crashed agent never released its claim).
    def reclaim_stale(ttl_minutes)
      cutoff = Time.now.utc - ttl_minutes * 60
      keep, drop = load.partition { |l| (Time.parse(l['claimed_at']) rescue Time.at(0)) > cutoff }
      drop.each { |l| git("update-ref -d #{l['ref']}") }
      save(keep) unless drop.empty?
      drop.size
    end
  end
end
