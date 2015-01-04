# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ANSI::Graphics do
    before do
      @subject = ANSI::Graphics
    end

    it 'returns the escape sequence for a text attribute' do
      @subject.text_attribute(:underline).should == "\e[4m"
    end

    it 'returns the escape sequence for a foreground color' do
      @subject.foreground_color(:red).should == "\e[31m"
    end

    it 'returns the escape sequence for a background color' do
      @subject.background_color(:green).should == "\e[42m"
    end

    it 'returns the escape sequence for an xterm-256 foreground color' do
      @subject.foreground_color_256(128).should == "\e[38;5;128m"
    end

    it 'returns the escape sequence for an xterm-256 background color' do
      @subject.background_color_256(128).should == "\e[48;5;128m"
    end

    it 'returns the escape sequence for a graphic mode code' do
      @subject.graphics_mode(31).should == "\e[31m"
    end

    it 'returns the escape sequence for a list of graphic mode codes' do
      @subject.graphics_mode([1, 31]).should == "\e[1;31m"
    end
  end
end
