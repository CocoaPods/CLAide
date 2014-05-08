# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)
load 'claide/ansi/string_mixin.rb'

module CLAide
  describe ANSI::StringMixin do

    before do
      @subject = 'test string'
    end

    it 'includes methods to set the foreground color' do
      @subject.yellow.should == "\e[33mtest string\e[39m"
    end

    it 'includes methods to set the background color' do
      @subject.on_red.should == "\e[41mtest string\e[49m"
    end

    it 'includes methods to set text attributes' do
      @subject.bold.should == "\e[1mtest string\e[21m"
    end

    it 'supports multiple nested foreground colors' do
      "#{@subject.red} example".green.should ==
        "\e[32m\e[31mtest string\e[32m example\e[39m"
    end

    it 'supports multiple nested foreground colors' do
      "#{@subject.on_red} example".on_green.should ==
        "\e[42m\e[41mtest string\e[42m example\e[49m"
    end

    it 'supports multiple nested text attributes' do
      "#{@subject.underline} example".bold.should ==
        "\e[1m\e[4mtest string\e[24m example\e[21m"
    end

    it 'clears a setting without resetting the whole graphics mode' do
      result = @subject.red
      result.should.not.include?("\e[0")
    end
  end
end

load 'claide/ansi/string_mixin_disable.rb'
