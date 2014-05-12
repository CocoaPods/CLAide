# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::ValidationHelper do
    before do
      @subject = Command::ValidationHelper
    end

    describe '::argument_suggestion' do
      it 'returns the message for a command' do
        arguments = ['spec_file']
        result = @subject.argument_suggestion(arguments, Fixture::Command)
        result.should == "Unknown command: `spec_file`\n" \
          'Did you mean: spec-file'
      end

      it 'returns the message for an option' do
        arguments = ['--verbosea']
        result = @subject.argument_suggestion(arguments, Fixture::Command)
        result.should ==
          "Unknown option: `--verbosea`\nDid you mean: --verbose"
      end
    end

    describe '::suggestion_list' do
      it 'returns the list of valid options' do
        expected = %w(--completion-script --version --verbose --no-ansi --help)
        @subject.suggestion_list(Fixture::Command, :option).should == expected
        @subject.suggestion_list(Fixture::Command, :flag).should == expected
      end

      it 'returns the list of valid subcommands' do
        expected = %w(spec-file)
        @subject.suggestion_list(Fixture::Command, :arg).should == expected
      end
    end
  end
end
