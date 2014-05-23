# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Argument do
    before do
      @subject = Argument
    end

    it 'converts a single name into a 1-item array' do
      @subject.new('STRING', true).names.should == ['STRING']
    end

    it 'accepts an array of names' do
      list = %w(FOO BAR BAZ)
      @subject.new(list, true).names.should == list
    end

    it 'should be non-repeatable by default' do
      @subject.new('REQUIRED', true).repeatable?.should.be.false?
      @subject.new('OPTIONAL', false).repeatable?.should.be.false?
    end
  end
end
