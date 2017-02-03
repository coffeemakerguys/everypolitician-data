#!/usr/bin/env ruby

# This script can catch errors where you've forgotten to rebuild
# countries.json.  It'll emit a warning and exit in error if it can't
# find a commit that's referenced in the countries.json file which
# isn't in the history of the current branch, or if the contents of
# the file that's referenced is different between the current version
# and the referenced one.

require 'everypolitician'
require 'set'

EveryPolitician.countries_json = 'countries.json'

def all_commits_in(commitish)
  IO.popen(['git', 'rev-list', commitish]).map(&:strip)
end

def extract_commit_and_path(url)
  object_name_re = %r{^\/everypolitician\/everypolitician-data\/([a-f0-9]+)\/(.*)$}
  URI.parse(url).path.match(object_name_re).captures
end

def file_same_between_commits(commit_a, commit_b, path)
  system('git', 'diff', '--quiet', commit_a, commit_b, '--', path)
end

def check_url(url, known_commits)
  commit, path = extract_commit_and_path(url)
  unless known_commits.include?(commit)
    puts "The referenced commit #{commit} was not in the history of this branch"
    return false
  end
  # If the commit is in our history, then check that the file is the
  # same between the tip of our branch and the version in that commit:
  if file_same_between_commits(commit, 'HEAD', path)
    true
  else
    puts "#{path} was different between #{commit} and HEAD"
    false
  end
end

known_commits = all_commits_in('HEAD').to_set

success = true

# For each country check the Popolo URL for the legislature and the
# CSV URL for each legislature:

EveryPolitician.countries.each do |c|
  c.legislatures.each do |l|
    success &&= check_url(l.popolo_url, known_commits)
    l.legislative_periods.each do |lp|
      success &&= check_url(lp.csv_url, known_commits)
    end
  end
end

exit(1) unless success
