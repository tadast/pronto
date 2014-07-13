require 'rugged'
require 'pronto/rugged/diff'
require 'pronto/rugged/diff/delta'
require 'pronto/rugged/diff/patch'
require 'pronto/rugged/diff/line'
require 'pronto/rugged/tree'
require 'pronto/rugged/remote'
require 'pronto/rugged/repository'
require 'pronto/rugged/commit'

require 'pronto/plugin'
require 'pronto/message'
require 'pronto/runner'

require 'pronto/formatter/text_formatter'
require 'pronto/formatter/json_formatter'
require 'pronto/formatter/github_formatter'
require 'pronto/formatter/checkstyle_formatter'
require 'pronto/formatter/formatter'

module Pronto
  def self.run(commit = 'master', repo_path = '.', formatter = nil)
    repo = Rugged::Repository.new(repo_path)
    commit ||= 'master'
    merge_base = repo.merge_base(commit, repo.head.target)
    patches = repo.diff(merge_base, repo.head.target)

    result = run_all_runners(patches, merge_base)

    formatter ||= default_formatter
    formatter.format(result, repo)
  end

  def self.gem_names
    gems = Gem::Specification.find_all.select do |gem|
      if gem.name =~ /^pronto-/
        true
      elsif gem.name != 'pronto'
        runner_path = File.join(gem.full_gem_path, "lib/pronto/#{gem.name}.rb")
        File.exists?(runner_path)
      end
    end

    gems.map { |gem| gem.name.sub(/^pronto-/, '') }
        .uniq
        .sort
  end

  private

  def self.run_all_runners(patches, commit)
    Runner.runners.map do |runner_class|
      runner = runner_class.new(patches, commit)
      runner.run
    end.flatten.compact
  end

  def default_formatter
    Formatter::TextFormatter.new
  end
end
