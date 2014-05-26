# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ARGV::Parser do
    before do
      @subject = ARGV::Parser
    end

    describe '::parse' do
      it 'handles regular arguments' do
        @subject.parse(%w(value)).should == [[:arg, 'value']]
      end

      it 'returns the parameter for a positive flag' do
        @subject.parse(%w(--value)).should == [[:flag, ['value', true]]]
      end

      it 'returns the parameter for a negative flag' do
        @subject.parse(%w(--no-value)).should == [[:flag, ['value', false]]]
      end

      it 'returns the parameter for an option' do
        @subject.parse(%w(--key=value)).should == [[:option, %w(key value)]]
      end

      it 'returns the parameter for a combination of arguments' do
        @subject.parse(%w(value --value --no-value --key=value)).should == [
          [:arg, 'value'],
          [:flag, ['value', true]],
          [:flag, ['value', false]],
          [:option, %w(key value)],
        ]
      end
    end
  end
end
