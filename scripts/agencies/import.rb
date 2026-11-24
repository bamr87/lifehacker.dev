#!/usr/bin/env ruby
# =============================================================================
# scripts/agencies/import.rb — bring one agency site tree in from its source
# -----------------------------------------------------------------------------
# An agency site is a self-contained tree under agencies/ (see agencies/README.md
# and docs/adr/0002-agencies.md). This is the only way a tree arrives or is
# refreshed: it exports the TRACKED files of one commit of a source repository,
# byte for byte, and records where they came from in _data/agencies.yml.
#
#   ruby scripts/agencies/import.rb <site path> --from <git checkout> [--ref <commit>] [--date YYYY-MM-DD]
#   ruby scripts/agencies/import.rb <site path> --from <git checkout> --verify
#   ruby scripts/agencies/import.rb --digest <site path>
#
#   <site path>   the site's `path` in _data/agencies.yml (agencies/drsai,
#                 agencies/year-of-ai/2006). Register the site first: an
#                 unregistered path is refused.
#   --from        a local checkout of the source repository named by the site's
#                 `source.repo`. Nothing is fetched; clone or pull it yourself.
#   --ref         the commit to export (default: HEAD of that checkout).
#   --verify      export to a temp directory and compare against the tree here,
#                 without writing. Exit 1 and list what differs.
#   --digest      print the tree digest of what is on disk and exit.
#
# The source's sub-directory comes from the registry (`source.path`, "." for a
# whole repository), so the command line cannot point a site at the wrong tree.
#
# The tree that lands is the source's bytes with two stated differences, both
# recorded in the registry so they are written down rather than discovered:
#
#   dropped   a tracked file of the source that THIS repository's ignore rules
#             refuse (.gitignore here and inside the tree — a stray .DS_Store,
#             an .env) is removed and listed under `source.dropped`.
#   reflowed  Markdown is held to this repository's one-paragraph-per-line rule
#             by the same repair the gate uses (tools/unwrap-prose.py, which
#             joins soft-wrapped prose and leaves structure byte for byte); the
#             number of files it changed is `source.reflowed`. Without this a
#             refreshed mirror would fail the gate on every import.
#
# --verify applies the same two steps to its temp export, so it compares like
# with like: "identical" means identical to the source after them.
#
# The tree digest is the SHA-256 of one line per file, sorted bytewise by path:
# "<sha256 of the file's bytes>  <path relative to the tree>\n" (a symlink is
# hashed as "link:<target>"). It is an import-time fact: content edited here
# afterwards changes it, and that is expected for a site whose custody is `home`.
#
# Stdlib only, Ruby 2.6+. Run from anywhere.
# =============================================================================
require 'open3'
require 'optparse'
require 'tmpdir'
require_relative '../ci/_lib'

REGISTRY = File.join(LH::ROOT, '_data', 'agencies.yml')

def die(msg)
  warn "import.rb: #{msg}"
  exit 2
end

def files_of(root)
  Dir.glob('**/*', File::FNM_DOTMATCH, base: root)
     .reject { |p| p == '.' || p.end_with?('/.') || File.directory?(File.join(root, p)) && !File.symlink?(File.join(root, p)) }
     .sort_by { |p| p.b }
end

def digest_of(root)
  lines = files_of(root).map do |rel|
    abs = File.join(root, rel)
    sum = File.symlink?(abs) ? Digest::SHA256.hexdigest("link:#{File.readlink(abs)}") : Digest::SHA256.file(abs).hexdigest
    "#{sum}  #{rel}\n"
  end
  [lines.size, Digest::SHA256.hexdigest(lines.join), lines]
end

# `git archive <sha> [<subdir>] | tar -x -C <dest> [--strip-components=N]`, with
# no shell: the ref and paths are data.
def export(from, sha, subdir, dest)
  FileUtils.mkdir_p(dest)
  archive = ['git', '-C', from, 'archive', '--format=tar', sha]
  tar     = ['tar', '-x', '-C', dest]
  unless subdir == '.'
    archive << subdir
    tar << "--strip-components=#{subdir.split('/').size}"
  end
  statuses = Open3.pipeline(archive, tar)
  die "export failed (git archive exit #{statuses[0].exitstatus}, tar exit #{statuses[1].exitstatus})" unless statuses.all?(&:success?)
end

# The exported files this repository ignores, as paths relative to the tree. The
# question is asked about the site's path here (--no-index: tracked or not), so
# it gives the same answer for a temp export as for the tree on disk.
def ignored_here(site_path, rels)
  return [] if rels.empty?
  input = rels.map { |r| "#{site_path}/#{r}" }.join("\0")
  out, = Open3.capture2('git', '-C', LH::ROOT, 'check-ignore', '--no-index', '--stdin', '-z', stdin_data: input)
  out.split("\0").map { |p| p.sub("#{site_path}/", '') }.sort_by { |p| p.b }
end

def drop_ignored(site_path, root)
  dropped = ignored_here(site_path, files_of(root))
  dropped.each { |rel| FileUtils.rm_f(File.join(root, rel)) }
  dropped
end

# One paragraph per line, by the gate's own tool and exclude list (the list is
# mirrored in scripts/ci/lint_oneline.rb and .github/workflows/markdown-oneline.yml).
# Returns how many files it rewrote.
UNWRAP = File.join(LH::ROOT, 'tools', 'unwrap-prose.py')
UNWRAP_EXCLUDES = ['(^|/)SCHEMA\.md$', '(^|/)CHANGELOG\.md$'].freeze

def reflow(root)
  cmd = ['python3', UNWRAP, '--write']
  UNWRAP_EXCLUDES.each { |e| cmd.push('--exclude', e) }
  out, err, status = Open3.capture3(*cmd, root)
  die "tools/unwrap-prose.py failed (exit #{status.exitstatus}): #{err.lines.first(3).join(' / ')}" unless status.success?
  out.lines.count { |l| l.start_with?('unwrapped ') }
end

opts = { ref: 'HEAD', date: Date.today.iso8601 }
parser = OptionParser.new do |o|
  o.banner = 'usage: import.rb <site path> --from <git checkout> [--ref <commit>] [--date YYYY-MM-DD] [--verify] | --digest <site path>'
  o.on('--from DIR')    { |v| opts[:from] = File.expand_path(v) }
  o.on('--ref REF')     { |v| opts[:ref] = v }
  o.on('--date DATE')   { |v| opts[:date] = v }
  o.on('--verify')      { opts[:verify] = true }
  o.on('--digest')      { opts[:digest] = true }
end
parser.parse!
site_path = ARGV.shift or die parser.banner
site_path = site_path.sub(%r{/+\z}, '')
die "#{site_path}: a site path is agencies/<agency> or agencies/<agency>/<site>" unless site_path =~ %r{\Aagencies/[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)?\z}
dest = File.join(LH::ROOT, site_path)

if opts[:digest]
  die "#{site_path} is not on disk" unless Dir.exist?(dest)
  count, sum, = digest_of(dest)
  puts "#{sum}  #{site_path}  (#{count} files)"
  exit 0
end

registry = LH.yload(LH.read(REGISTRY))
site = (registry['agencies'] || []).flat_map { |a| a['sites'] || [] }.find { |s| s['path'] == site_path }
die "#{site_path} is not registered in _data/agencies.yml — add the agency and the site there first" unless site
source = site['source'] or die "#{site_path} has no `source:` block in the registry"
subdir = (source['path'] || '.').to_s.sub(%r{/+\z}, '')
subdir = '.' if subdir.empty?
die '--from <git checkout> is required' unless opts[:from]

sha, status = Open3.capture2('git', '-C', opts[:from], 'rev-parse', '--verify', "#{opts[:ref]}^{commit}")
die "#{opts[:ref]} is not a commit in #{opts[:from]}" unless status.success?
sha = sha.strip

if opts[:verify]
  Dir.mktmpdir('agency-verify') do |tmp|
    export(opts[:from], sha, subdir, tmp)
    drop_ignored(site_path, tmp)
    reflow(tmp)
    _, want, want_lines = digest_of(tmp)
    _, have, have_lines = Dir.exist?(dest) ? digest_of(dest) : [0, '', []]
    if want == have
      puts "#{site_path}: identical to #{source['repo']}@#{sha[0, 12]}:#{subdir} (#{want_lines.size} files)"
      exit 0
    end
    (want_lines - have_lines).first(20).each { |l| puts "  source only or changed: #{l.split('  ', 2).last}" }
    (have_lines - want_lines).first(20).each { |l| puts "  here only or changed:   #{l.split('  ', 2).last}" }
    puts "#{site_path}: differs from #{source['repo']}@#{sha[0, 12]}:#{subdir}"
    exit 1
  end
end

FileUtils.rm_rf(dest)
export(opts[:from], sha, subdir, dest)
dropped = drop_ignored(site_path, dest)
reflowed = reflow(dest)
count, sum, = digest_of(dest)
die "#{site_path}: the export is empty — is `source.path` (#{subdir}) right for #{opts[:from]}?" if count.zero?

record = source.merge('path' => subdir, 'commit' => sha, 'imported' => opts[:date], 'files' => count, 'tree_sha256' => sum)
%w[dropped reflowed].each { |k| record.delete(k) }
record['reflowed'] = reflowed unless reflowed.zero?
record['dropped'] = dropped unless dropped.empty?
site['source'] = record
LH.ywrite(REGISTRY, registry)
puts "#{site_path}: #{count} files from #{source['repo']}@#{sha[0, 12]}:#{subdir}  tree #{sum[0, 16]}…  reflowed #{reflowed}"
dropped.each { |rel| puts "  dropped (ignored here): #{rel}" }
