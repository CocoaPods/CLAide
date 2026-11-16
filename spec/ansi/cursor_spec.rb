
require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ANSI::Cursor do
    before do
      @subject = ANSI::Cursor
    end

    it 'returns the escape sequence to set the cursor position' do
      expect(@subject.set_cursor_position(10, 15)).to eq("\e[10;15H")
    end

    it 'returns the escape sequence to move the cursor up' do
      expect(@subject.move_cursor(-2, 0)).to eq("\e[2A;0D")
    end

    it 'returns the escape sequence to move the cursor down' do
      expect(@subject.move_cursor(2, 0)).to eq("\e[2B;0D")
    end

    it 'returns the escape sequence to move the cursor left' do
      expect(@subject.move_cursor(0, -2)).to eq("\e[0B;2D")
    end

    it 'returns the escape sequence to move the cursor right' do
      expect(@subject.move_cursor(0, 2)).to eq("\e[0B;2C")
    end

    it 'returns the escape sequence to move vertically and horizontally' do
      expect(@subject.move_cursor(2, -2)).to eq("\e[2B;2D")
    end

    it 'returns the escape sequence to save the cursor position' do
      expect(@subject.save_cursor_position).to eq("\e[s")
    end

    it 'returns the escape sequence to restore the cursor position' do
      expect(@subject.restore_cursor_position).to eq("\e[u")
    end

    it 'returns the escape sequence to erase the display' do
      expect(@subject.erase_display).to eq("\e[2J")
    end

    it 'returns the escape sequence to erase the line' do
      expect(@subject.erase_line).to eq("\e[K")
    end
  end
end
