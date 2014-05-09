# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)
load 'claide/ansi/string_mixin_disable.rb'

module CLAide
  describe ANSI::StringDisabledEscaper do
    before do
      @subject = 'test string'
    end

    it 'includes methods to set the foreground color' do
      @subject.ansi.yellow.should == @subject
    end

    it 'includes methods to set the background color' do
      @subject.ansi.on_red.should == @subject
    end

    it 'includes methods to set text attributes' do
      @subject.ansi.bold.should == @subject
    end

    it 'disables the support for ANSI sequences even if it was enabled' do
      load 'claide/ansi/string_mixin.rb'
      @subject.ansi.yellow.should == "\e[33mtest string\e[39m"

      load 'claide/ansi/string_mixin_disable.rb'
      @subject.ansi.yellow.should == @subject
    end
  end
end

load 'claide/ansi/string_mixin_disable.rb'
