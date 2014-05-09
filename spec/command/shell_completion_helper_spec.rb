# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::ShellCompletionHelper do
    before do
      @subject = Command::ShellCompletionHelper
    end

    describe '::completion_template' do
      it 'returns the completion helper for the given shell' do
        result = @subject.completion_template(Fixture::Command, 'zsh')
        result.should.start_with?('#compdef bin')
      end

      it 'infers the given shell is one is not provided' do
        ENV.stubs(:[]).with('SHELL').returns('zsh')
        @subject::ZSHCompletionGenerator.expects(:generate).once
        @subject.completion_template(Fixture::Command)
      end

      it 'raises if unable to support the shell' do
        should.raise Help do
          @subject.completion_template(Fixture::Command, 'heheshell!')
        end.message.should.include?('shell not implemented')
      end
    end

    describe '::indent' do
      it 'indents the given string by the given amount' do
        @subject.indent("line 1\nline 2", 1).should == "line 1\n  line 2"
      end

      it 'it does not indent the first line' do
        @subject.indent("line 1\nline 2", 1).should.start_with?('line 1')
      end
    end
  end
end
