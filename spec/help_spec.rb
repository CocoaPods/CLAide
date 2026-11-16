# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Help do
    #-------------------------------------------------------------------------#

    describe 'in general' do
      it 'shows just the banner if no error message is specified' do
        banner = 'A descriptive banner'
        expect(Help.new(banner).message).to eq(banner)
      end

      it 'shows the specified error message before the rest of the banner' do
        banner = 'A descriptive banner'
        error_message = 'Unable to process, captain.'
        expected = "[!] #{error_message}\n\n#{banner}"
        expect(Help.new(banner, error_message).message).to eq(expected)
      end
    end

    #-------------------------------------------------------------------------#
  end
end
