# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

class CLAide::Command
  describe ArgumentSuggester do
    describe '::levenshtein_distance' do
      it 'returns the distance among two strings' do
        suggester = ArgumentSuggester
        expect(suggester.levenshtein_distance('word 1', 'word 2')).to eq(1)
        expect(suggester.levenshtein_distance('word 1', 'dictionary')).to eq(9)
      end
    end

    describe '#possibilities' do
      it 'returns the list of valid options' do
        expected = %w(--version --verbose --no-ansi --help)

        suggester = ArgumentSuggester.new('--option', Fixture::Command)
        expect(suggester.possibilities).to eq(expected)

        suggester = ArgumentSuggester.new('--flag', Fixture::Command)
        expect(suggester.possibilities).to eq(expected)
      end

      it 'returns the list of valid subcommands' do
        suggester = ArgumentSuggester.new('command', Fixture::Command)
        expect(suggester.possibilities).to eq(%w(spec-file))
      end
    end

    describe '#suggestion' do
      it 'returns the message for a command' do
        result = ArgumentSuggester.new('spec_file', Fixture::Command).suggestion
        expect(result).
          to eq("Unknown command: `spec_file`\nDid you mean: spec-file?")
      end

      it 'returns the message for when no suggestion is possible' do
        suggester = ArgumentSuggester.new('spec_file', Fixture::Command)
        suggester.stubs(:possibilities).returns([])
        expect(suggester.suggestion).to eq('Unknown command: `spec_file`')
      end

      it 'returns the message for an option' do
        result = ArgumentSuggester.new('--verbosa', Fixture::Command).suggestion
        expect(result).
          to eq("Unknown option: `--verbosa`\nDid you mean: --verbose?")
      end
    end
  end
end
