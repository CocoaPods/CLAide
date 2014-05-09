# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::ValidateHelper do
    before do
      @subject = Command::ValidateHelper
    end

    describe '::unknown_arguments_message' do
      it 'returns the message for a command' do
        unknown = 'installs'
        suggestions = ['help', 'update', 'install']
        type = :command
        result = @subject.unknown_arguments_message(unknown, suggestions, type)
        result.should == "Unknown command: `installs`\nDid you mean: install"
      end

      it 'returns the message for an option' do
        unknown = '--verbosea'
        suggestions = ['help', 'verbose', 'silent']
        type = :option
        result = @subject.unknown_arguments_message(unknown, suggestions, type)
        result.should == "Unknown option: `--verbosea`\nDid you mean: --verbose"
      end
    end
  end
end
