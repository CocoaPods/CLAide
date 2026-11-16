# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe ARGV do
    describe 'in general' do
      before do
        parameters = %w(--flag --option=VALUE ARG1 ARG2 --no-other-flag)
        @argv = ARGV.new(parameters)
      end

      it 'converts objects into strings while parsing' do
        flag = stub(:to_s => '--flag')
        arg = stub(:to_s => 'ARG')
        expect(ARGV.new([flag, arg]).remainder).to eq(%w(--flag ARG))
      end

      it 'only removes one entry when calling shift_argument' do
        argv = ARGV.new(%w(ARG ARG))
        argv.shift_argument
        expect(argv.remainder).to eq(%w(ARG))
      end

      it 'returns the options as a hash' do
        expect(@argv.options).to eq(
          'flag' => true,
          'other-flag' => false,
          'option' => 'VALUE',
        )
      end

      it 'returns the arguments' do
        expect(@argv.arguments).to eq(%w(ARG1 ARG2))
      end

      it 'returns a flag and deletes it' do
        expect(@argv.flag?('flag')).to eq(true)
        expect(@argv.flag?('other-flag')).to eq(false)
        expect(@argv.flag?('option')).to be_nil
        expect(@argv.remainder).to eq(%w(--option=VALUE ARG1 ARG2))
      end

      it 'returns a default value if a flag does not exist' do
        expect(@argv.flag?('option', true)).to eq(true)
        expect(@argv.flag?('option', false)).to eq(false)
      end

      it 'allows multiple values for the same flag' do
        argv = ARGV.new(%w(--verbose --no-verbose))
        expect(argv.flag?('verbose')).to eq(false)
        expect(argv.remainder).to eq([])

        argv = ARGV.new(%w(--verbose --verbose))
        expect(argv.flag?('verbose')).to eq(true)
        expect(argv.remainder).to eq([])
      end

      it 'returns an option and deletes it' do
        expect(@argv.option('flag')).to be_nil
        expect(@argv.option('other-flag')).to be_nil
        expect(@argv.option('option')).to eq('VALUE')
        expect(@argv.remainder).to eq(%w(--flag ARG1 ARG2 --no-other-flag))
      end

      it 'allows multiple values for the same option' do
        @argv = ARGV.new %w(--ignore=foo --ignore=bar)
        expect(@argv.option('ignore')).to eq('bar')
        expect(@argv.option('ignore')).to eq('foo')
        expect(@argv.option('ignore')).to be_nil
      end

      it 'returns all values for the same option' do
        @argv = ARGV.new %w(--ignore=foo --ignore=bar)
        expect(@argv.all_options('ignore')).to eq(%w(bar foo))
        expect(@argv.all_options('ignore')).to eq([])
        expect(@argv.all_options('include')).to eq([])
        expect(@argv.option('ignore')).to be_nil
      end

      it 'returns a default value if an option does not exist' do
        expect(@argv.option('flag', 'value')).to eq('value')
      end

      it 'returns the first argument and deletes it' do
        expect(@argv.shift_argument).to eq('ARG1')
        expect(@argv.remainder).
          to eq(%w(--flag --option=VALUE ARG2 --no-other-flag))
      end

      it 'returns and deletes all arguments' do
        expect(@argv.arguments!).to eq(%w(ARG1 ARG2))
        expect(@argv.remainder).to eq(%w(--flag --option=VALUE --no-other-flag))
      end

      describe '#remainder!' do
        it 'returns the remainder and removes all entries' do
          args = %w(--flag --option=VALUE ARG1 ARG2 --no-other-flag)
          expect(@argv.remainder).to eq(args)
          expect(@argv.remainder!).to eq(args)
          expect(@argv.remainder).to eq([])
        end
      end
    end
  end

  describe ARGV::Parser do
    before do
      @parser = ARGV::Parser
    end

    describe '::parse' do
      it 'handles regular arguments' do
        expect(@parser.parse(%w(value))).to eq([[:arg, 'value']])
      end

      it 'returns the parameter for a positive flag' do
        expect(@parser.parse(%w(--value))).to eq([[:flag, ['value', true]]])
      end

      it 'returns the parameter for a negative flag' do
        expect(@parser.parse(%w(--no-value))).to eq([[:flag, ['value', false]]])
      end

      it 'returns the parameter for an option' do
        expect(@parser.parse(%w(--key=value))).to eq([[:option, %w(key value)]])
      end

      it 'returns the parameter for a combination of arguments' do
        expected = [
          [:arg, 'value'],
          [:flag, ['value', true]],
          [:flag, ['value', false]],
          [:option, %w(key value)],
        ]
        expect(@parser.parse(%w(value --value --no-value --key=value))).
          to eq(expected)
      end

      describe '--' do
        it 'parses everything after -- as an arg' do
          argv = %w(value -- -- value --no-value -- --key=value)
          expected = [
            [:arg, 'value'],
            [:arg, '--'],
            [:arg, 'value'],
            [:arg, '--no-value'],
            [:arg, '--'],
            [:arg, '--key=value'],
          ]
          expect(@parser.parse(argv)).to eq(expected)
        end
      end
    end
  end
end
