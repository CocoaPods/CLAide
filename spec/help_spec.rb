# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Help do

    #-------------------------------------------------------------------------#

    describe 'in general' do

      it 'shows just the banner if no error message is specified' do
        banner = 'A descriptive banner'
        Help.new(banner).message.should == banner
      end

      it 'shows the specified error message before the rest of the banner' do
        banner = 'A descriptive banner'
        error_message = 'Unable to process, captain.'
        expected = "[!] #{error_message}\n\n#{banner}"
        Help.new(banner, error_message).message.should == expected
      end
    end

    #-------------------------------------------------------------------------#

  end
end
