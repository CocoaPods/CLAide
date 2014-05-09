# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe ARGV do

    #-------------------------------------------------------------------------#

    describe 'in general' do

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

      before do
        @argv = ARGV.new(%w(--flag --option=VALUE ARG1 ARG2 --no-other-flag))
      end

      it 'returns the options as a hash' do
        @argv.options.should == {
          'flag' => true,
          'other-flag' => false,
          'option' => 'VALUE'
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
        @argv.remainder.should == %w(--flag --option=VALUE ARG2 --no-other-flag)
      end

      it 'returns and deletes all arguments' do
        @argv.arguments!.should == %w(ARG1 ARG2)
        @argv.remainder.should == %w(--flag --option=VALUE --no-other-flag)
      end
    end

    #-------------------------------------------------------------------------#

  end
end
