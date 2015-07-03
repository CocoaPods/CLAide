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
        ARGV.new([flag, arg]).remainder.should == %w(--flag ARG)
      end

      it 'only removes one entry when calling shift_argument' do
        argv = ARGV.new(%w(ARG ARG))
        argv.shift_argument
        argv.remainder.should == %w(ARG)
      end

      it 'returns the options as a hash' do
        @argv.options.should == {
          'flag' => true,
          'other-flag' => false,
          'option' => 'VALUE',
        }
      end

      it 'returns the arguments' do
        @argv.arguments.should == %w(ARG1 ARG2)
      end

      it 'returns a flag and deletes it' do
        @argv.flag?('flag').should == true
        @argv.flag?('other-flag').should == false
        @argv.flag?('option').should.nil?
        @argv.remainder.should == %w(--option=VALUE ARG1 ARG2)
      end

      it 'returns a default value if a flag does not exist' do
        @argv.flag?('option', true).should == true
        @argv.flag?('option', false).should == false
      end

      it 'allows multiple values for the same flag' do
        argv = ARGV.new(%w(--verbose --no-verbose))
        argv.flag?('verbose').should == false
        argv.remainder.should == []

        argv = ARGV.new(%w(--verbose --verbose))
        argv.flag?('verbose').should == true
        argv.remainder.should == []
      end

      it 'returns an option and deletes it' do
        @argv.option('flag').should.nil?
        @argv.option('other-flag').should.nil?
        @argv.option('option').should == 'VALUE'
        @argv.remainder.should == %w(--flag ARG1 ARG2 --no-other-flag)
      end

      it 'allows multiple values for the same option' do
        @argv = ARGV.new %w(--ignore=foo --ignore=bar)
        @argv.option('ignore').should == 'bar'
        @argv.option('ignore').should == 'foo'
        @argv.option('ignore').should.be.nil
      end

      it 'returns all values for the same option' do
        @argv = ARGV.new %w(--ignore=foo --ignore=bar)
        @argv.all_options('ignore').should == %w(bar foo)
        @argv.all_options('ignore').should == []
        @argv.all_options('include').should == []
        @argv.option('ignore').should.be.nil
      end

      it 'returns a default value if an option does not exist' do
        @argv.option('flag', 'value').should == 'value'
      end

      it 'returns the first argument and deletes it' do
        @argv.shift_argument.should == 'ARG1'
        @argv.remainder.should ==
          %w(--flag --option=VALUE ARG2 --no-other-flag)
      end

      it 'returns and deletes all arguments' do
        @argv.arguments!.should == %w(ARG1 ARG2)
        @argv.remainder.should == %w(--flag --option=VALUE --no-other-flag)
      end

      describe '#remainder!' do
        it 'returns the remainder and removes all entries' do
          args = %w(--flag --option=VALUE ARG1 ARG2 --no-other-flag)
          @argv.remainder.should == args
          @argv.remainder!.should == args
          @argv.remainder.should == []
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
        @parser.parse(%w(value)).should == [[:arg, 'value']]
      end

      it 'returns the parameter for a positive flag' do
        @parser.parse(%w(--value)).should == [[:flag, ['value', true]]]
      end

      it 'returns the parameter for a negative flag' do
        @parser.parse(%w(--no-value)).should == [[:flag, ['value', false]]]
      end

      it 'returns the parameter for an option' do
        @parser.parse(%w(--key=value)).should == [[:option, %w(key value)]]
      end

      it 'returns the parameter for a combination of arguments' do
        @parser.parse(%w(value --value --no-value --key=value)).should == [
          [:arg, 'value'],
          [:flag, ['value', true]],
          [:flag, ['value', false]],
          [:option, %w(key value)],
        ]
      end

      describe '--' do
        it 'parses everything after -- as an arg' do
          argv = %w(value -- -- value --no-value -- --key=value)
          @parser.parse(argv).should == [
            [:arg, 'value'],
            [:arg, '--'],
            [:arg, 'value'],
            [:arg, '--no-value'],
            [:arg, '--'],
            [:arg, '--key=value'],
          ]
        end
      end
    end
  end
end
