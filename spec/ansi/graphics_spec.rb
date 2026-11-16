# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ANSI::Graphics do
    before do
      @subject = ANSI::Graphics
    end

    it 'returns the escape sequence for a text attribute' do
      expect(@subject.text_attribute(:underline)).to eq("\e[4m")
    end

    it 'returns the escape sequence for a foreground color' do
      expect(@subject.foreground_color(:red)).to eq("\e[31m")
    end

    it 'returns the escape sequence for a background color' do
      expect(@subject.background_color(:green)).to eq("\e[42m")
    end

    it 'returns the escape sequence for an xterm-256 foreground color' do
      expect(@subject.foreground_color_256(128)).to eq("\e[38;5;128m")
    end

    it 'returns the escape sequence for an xterm-256 background color' do
      expect(@subject.background_color_256(128)).to eq("\e[48;5;128m")
    end

    it 'returns the escape sequence for a graphic mode code' do
      expect(@subject.graphics_mode(31)).to eq("\e[31m")
    end

    it 'returns the escape sequence for a list of graphic mode codes' do
      expect(@subject.graphics_mode([1, 31])).to eq("\e[1;31m")
    end
  end
end
