module Pronto
  class Runner < Struct.new(:patches, :commit)
    include Plugin

    def ruby_patches
      @ruby_patches ||= begin
        patches_with_additions.select { |patch| ruby_patch?(patch) }
      end
    end

    def ruby_patch?(patch)
      ruby_file?(patch.new_file_full_path)
    end

    def ruby_file?(path)
      File.extname(path) == '.rb' || ruby_executable?(path)
    end

    def patches_with_additions
      @patches_with_additions ||= begin
        patches.select { |patch| patch.additions > 0 }
      end
    end

    def self.runners
      repository
    end

    private

    def ruby_executable?(path)
      line = File.open(path) { |file| file.readline }
      line =~ /#!.*ruby/
    rescue ArgumentError, EOFError
      false
    end
  end
end
