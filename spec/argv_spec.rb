# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe ARGV do
    describe 'in general' do
      before do
        parameters = %w(--flag --option=VALUE ARG1 ARG2 --no-other-flag)
        @subject = ARGV.new(parameters)
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
        @subject.options.should == {
          'flag' => true,
          'other-flag' => false,
          'option' => 'VALUE',
        }
      end

      it 'returns the arguments' do
        @subject.arguments.should == %w(ARG1 ARG2)
      end

      it 'returns a flag and deletes it' do
        @subject.flag?('flag').should == true
        @subject.flag?('other-flag').should == false
        @subject.flag?('option').should.nil?
        @subject.remainder.should == %w(--option=VALUE ARG1 ARG2)
      end

      it 'returns a default value if a flag does not exist' do
        @subject.flag?('option', true).should == true
        @subject.flag?('option', false).should == false
      end

      it 'returns an option and deletes it' do
        @subject.option('flag').should.nil?
        @subject.option('other-flag').should.nil?
        @subject.option('option').should == 'VALUE'
        @subject.remainder.should == %w(--flag ARG1 ARG2 --no-other-flag)
      end

      it 'returns a default value if an option does not exist' do
        @subject.option('flag', 'value').should == 'value'
      end

      it 'returns the first argument and deletes it' do
        @subject.shift_argument.should == 'ARG1'
        @subject.remainder.should ==
          %w(--flag --option=VALUE ARG2 --no-other-flag)
      end

      it 'returns and deletes all arguments' do
        @subject.arguments!.should == %w(ARG1 ARG2)
        @subject.remainder.should == %w(--flag --option=VALUE --no-other-flag)
      end
    end
  end
end
