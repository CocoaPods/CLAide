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

      it 'returns an option and deletes it' do
        @argv.option('flag').should.nil?
        @argv.option('other-flag').should.nil?
        @argv.option('option').should == 'VALUE'
        @argv.remainder.should == %w(--flag ARG1 ARG2 --no-other-flag)
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
    end
  end
end
