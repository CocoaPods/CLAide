# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe ANSI do
    before do
      @subject = ANSI
    end

    describe '::code_for_key' do
      it 'returns the code for a given key' do
        expect(@subject.code_for_key(:red, ANSI::COLORS)).to eq(1)
      end

      it 'raises if the key is nil' do
        expect do
          @subject.code_for_key(nil, ANSI::COLORS)
        end.to raise_error(ArgumentError, /A key must be provided/)
      end

      it 'raises if the key is nil' do
        expect do
          @subject.code_for_key(:bold, ANSI::COLORS)
        end.to raise_error(ArgumentError, /Unsupported key/)
      end
    end

    describe 'String mixin' do
      it 'enables the support for ANSI sequences even if it was disabled' do
        @subject.disabled = true
        expect('test string'.ansi.yellow).to eq('test string')

        @subject.disabled = false
        expect('test string'.ansi.yellow).to eq("\e[33mtest string\e[39m")
      end
    end
  end
end
