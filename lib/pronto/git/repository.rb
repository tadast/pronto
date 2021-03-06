require 'pathname'

module Pronto
  module Git
    class Repository
      def initialize(path)
        @repo = Rugged::Repository.new(path)
      end

      def github_slug
        remotes.map(&:github_slug).compact.first
      end

      def diff(commit)
        merge_base = merge_base(commit)
        patches = @repo.diff(merge_base, head)
        Patches.new(self, merge_base, patches)
      end

      def show_commit(sha)
        return [] unless sha

        commit = @repo.lookup(sha)
        return [] if commit.parents.count != 1

        # TODO: Rugged does not seem to support diffing against multiple parents
        diff = commit.diff(reverse: true)
        return [] if diff.nil?

        Patches.new(self, sha, diff.patches)
      end

      def commits_until(sha)
        result = []
        @repo.walk('HEAD', Rugged::SORT_TOPO).take_while do |commit|
          result << commit.oid
          !commit.oid.start_with?(sha)
        end
        result
      end

      def path
        Pathname.new(@repo.path).parent
      end

      def blame(patch, lineno)
        Rugged::Blame.new(@repo, patch.delta.new_file[:path],
                          min_line: lineno, max_line: lineno,
                          track_copies_same_file: true,
                          track_copies_any_commit_copies: true)[0]
      end

      private

      def merge_base(commit)
        @repo.merge_base(commit, head)
      end

      def head
        @repo.head.target
      end

      def remotes
        @remotes ||= @repo.remotes.map { |remote| Remote.new(remote) }
      end
    end
  end
end
