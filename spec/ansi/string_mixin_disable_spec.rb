# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)
load 'claide/ansi/string_mixin_disable.rb'

module CLAide
  describe ANSI::StringMixinDisable do

    before do
      @subject = 'test string'
    end

    it 'includes methods to set the foreground color' do
      @subject.yellow.should == @subject
    end

    it 'includes methods to set the background color' do
      @subject.on_red.should == @subject
    end

    it 'includes methods to set text attributes' do
      @subject.bold.should == @subject
    end

    it 'overrides the StringMixin even if already loaded' do
      load 'claide/ansi/string_mixin.rb'
      @subject.yellow.should == "\e[33mtest string\e[39m"

      load 'claide/ansi/string_mixin_disable.rb'
      @subject.yellow.should == @subject
    end
  end
end

load 'claide/ansi/string_mixin_disable.rb'
