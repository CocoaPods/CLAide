# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ANSI::Cursor do

    before do
      @subject = ANSI::Cursor
    end

    it 'returns the escape sequence to set the cursor position' do
      @subject.set_cursor_position(10, 15).should == "\e[10;15H"
    end

    it 'returns the escape sequence to move the cursor up' do
      @subject.move_cursor(-2, 0).should == "\e[2A"
    end

    it 'returns the escape sequence to move the cursor down' do
      @subject.move_cursor(2, 0).should == "\e[2B"
    end

    it 'returns the escape sequence to move the cursor left' do
      @subject.move_cursor(0, -2).should == "\e[2D"
    end

    it 'returns the escape sequence to move the cursor right' do
      @subject.move_cursor(0, 2).should == "\e[2C"
    end

    it 'returns the escape sequence to move vertically and horizontally' do
      @subject.move_cursor(2, -2).should == "\e[2B;2D"
    end

    it 'returns the escape sequence to save the cursor position' do
      @subject.save_cursor_position.should == "\e[s"
    end

    it 'returns the escape sequence to restore the cursor position' do
      @subject.restore_cursor_position.should == "\e[u"
    end

    it 'returns the escape sequence to erase the display' do
      @subject.erase_display.should == "\e[2J"
    end

    it 'returns the escape sequence to erase the line' do
      @subject.erase_line.should == "\e[K"
    end
  end
end
