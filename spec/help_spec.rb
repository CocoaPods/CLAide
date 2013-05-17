require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Help, "formatting for a command" do
    it "shows just the banner if no error message is specified" do
      command = Fixture::Command.parse([])
      Help.new(command).message.should == command.formatted_banner
    end

    it "shows the specified error message before the rest of the banner" do
      command = Fixture::Command.parse([])
      Help.new(command, "Unable to process, captain.").message.should == <<-BANNER.rstrip
[!] Unable to process, captain.

#{command.formatted_banner}
BANNER
    end
  end
end
