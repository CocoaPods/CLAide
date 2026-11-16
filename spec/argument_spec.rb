# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Argument do
    before do
      @subject = Argument
    end

    it 'converts a single name into a 1-item array' do
      expect(@subject.new('STRING', true).names).to eq(['STRING'])
    end

    it 'accepts an array of names' do
      list = %w(FOO BAR BAZ)
      expect(@subject.new(list, true).names).to eq(list)
    end

    it 'should be non-repeatable by default' do
      expect(@subject.new('REQUIRED', true).repeatable?).to be(false)
      expect(@subject.new('OPTIONAL', false).repeatable?).to be(false)
    end
  end
end
