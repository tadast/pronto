require 'spec_helper'

module Pronto
  describe Runner do
    let(:runner) { Runner.new(patches) }
    let(:patches) { [] }

    shared_examples 'ruby file matcher' do
      context 'ending with .rb' do
        let(:path) { 'test.rb' }
        it { should be_true }
      end

      context 'ending with .rb in directory' do
        let(:path) { 'amazing/test.rb' }
        it { should be_true }
      end

      context 'executable' do
        let(:path) { 'test' }
        before { File.stub(:open).with(path).and_return(shebang) }

        context 'ruby' do
          let(:shebang) { '#!ruby' }
          it { should be_true }
        end

        context 'bash' do
          let(:shebang) { '#! bash' }
          it { should be_false }
        end
      end
    end

    describe '#ruby_patch?' do
      subject { runner.ruby_patch?(patch) }
      let(:patch) { double(:patch, new_file_full_path: path) }
      it_behaves_like 'ruby file matcher'
    end

    describe '#ruby_file?' do
      subject { runner.ruby_file?(path) }
      it_behaves_like 'ruby file matcher'
    end

    describe '#patches_with_additions' do
      subject { runner.patches_with_additions }

      context 'with additions' do
        let(:patches) { [double(:patch, additions: 1)] }
        its(:count) { should == 1 }
      end

      context 'without additions' do
        let(:patches) { [double(:patch, additions: 0)] }
        its(:count) { should == 0 }
      end
    end
  end
end
