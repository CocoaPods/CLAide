# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe ANSI::StringEscaper do
    before do
      ANSI.disabled = false
      @subject = 'test string'
    end

    it "doesn't edit in place the original string" do
      expect(@subject.ansi.yellow).to eq("\e[33mtest string\e[39m")
      expect(@subject).to eq('test string')
    end

    it 'supports chaining' do
      expect(@subject.ansi.yellow.bold).
        to eq("\e[1m\e[33mtest string\e[39m\e[21m")
    end

    it 'allows to apply a single key' do
      expect(@subject.ansi.apply(:yellow)).to eq("\e[33mtest string\e[39m")
    end

    it 'allows to apply a multiple keys' do
      expect(@subject.ansi.apply(:yellow, :bold)).
        to eq("\e[1m\e[33mtest string\e[39m\e[21m")

      expect(@subject.ansi.apply([:yellow, :bold])).
        to eq("\e[1m\e[33mtest string\e[39m\e[21m")
    end

    it 'includes methods to set the foreground color' do
      expect(@subject.ansi.yellow).to eq("\e[33mtest string\e[39m")
    end

    it 'includes methods to set the background color' do
      expect(@subject.ansi.on_red).to eq("\e[41mtest string\e[49m")
    end

    it 'includes methods to set text attributes' do
      expect(@subject.ansi.bold).to eq("\e[1mtest string\e[21m")
    end

    it 'supports multiple nested foreground colors' do
      expect("#{@subject.ansi.red} example".ansi.green).
        to eq("\e[32m\e[31mtest string\e[32m example\e[39m")
    end

    it 'supports multiple nested foreground colors' do
      expect("#{@subject.ansi.on_red} example".ansi.on_green).
        to eq("\e[42m\e[41mtest string\e[42m example\e[49m")
    end

    it 'supports multiple nested text attributes' do
      expect("#{@subject.ansi.underline} example".ansi.bold).
        to eq("\e[1m\e[4mtest string\e[24m example\e[21m")
    end

    it 'clears a setting without resetting the whole graphics mode' do
      result = @subject.ansi.red
      expect(result).not_to include("\e[0")
    end

    it 'enables the support for ANSI sequences even if it was disabled' do
      ANSI.disabled = true
      expect(@subject.ansi.yellow).to eq(@subject)

      ANSI.disabled = false
      expect(@subject.ansi.yellow).to eq("\e[33mtest string\e[39m")
    end
  end
end
