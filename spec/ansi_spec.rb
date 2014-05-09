# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe ANSI do
    describe 'String mixin' do
      it 'enables the support for ANSI sequences even if it was disabled' do
        ANSI.disabled = true
        'test string'.ansi.yellow.should == 'test string'

        ANSI.disabled = false
        'test string'.ansi.yellow.should == "\e[33mtest string\e[39m"
      end
    end
  end
end
