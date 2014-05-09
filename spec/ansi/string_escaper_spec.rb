# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ANSI::StringEscaper do
    before do
      ANSI.disabled = false
      @subject = 'test string'
    end

    it 'includes methods to set the foreground color' do
      @subject.ansi.yellow.should == "\e[33mtest string\e[39m"
    end

    it 'includes methods to set the background color' do
      @subject.ansi.on_red.should == "\e[41mtest string\e[49m"
    end

    it 'includes methods to set text attributes' do
      @subject.ansi.bold.should == "\e[1mtest string\e[21m"
    end

    it 'supports multiple nested foreground colors' do
      "#{@subject.ansi.red} example".ansi.green.should ==
        "\e[32m\e[31mtest string\e[32m example\e[39m"
    end

    it 'supports multiple nested foreground colors' do
      "#{@subject.ansi.on_red} example".ansi.on_green.should ==
        "\e[42m\e[41mtest string\e[42m example\e[49m"
    end

    it 'supports multiple nested text attributes' do
      "#{@subject.ansi.underline} example".ansi.bold.should ==
        "\e[1m\e[4mtest string\e[24m example\e[21m"
    end

    it 'clears a setting without resetting the whole graphics mode' do
      result = @subject.ansi.red
      result.should.not.include?("\e[0")
    end

    it 'enables the support for ANSI sequences even if it was disabled' do
      ANSI.disabled = true
      @subject.ansi.yellow.should == @subject

      ANSI.disabled = false
      @subject.ansi.yellow.should == "\e[33mtest string\e[39m"
    end
  end
end
