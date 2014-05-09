# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::Banner do

    #-------------------------------------------------------------------------#

    describe 'in general' do

      it 'does not include a usage banner for an abstract command' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        banner.formatted_banner.should ==
          <<-BANNER.strip_margin('|').rstrip
            |Manage spec files.
            |
            |Commands:
            |
            |#{banner.send(:formatted_subcommand_summaries)}
            |
            |Options:
            |
            |#{banner.send(:formatted_options_description)}
        BANNER
      end

      it 'combines the summary/description, commands, and options' do
        banner = Command::Banner.new(Fixture::Command::SpecFile::Create)
        banner.formatted_banner.should ==
          <<-BANNER.strip_margin('|').rstrip
            |Usage:
            |
            |#{banner.send(:formatted_usage_description)}
            |
            |Options:
            |
            |#{banner.send(:formatted_options_description)}
        BANNER
      end
    end

    #-------------------------------------------------------------------------#

    describe 'banner components' do
      it "returns a usage description based on the command's description" do
        banner = Command::Banner.new(Fixture::Command::SpecFile::Create)
        banner.send(:formatted_usage_description).should ==
          <<-USAGE.strip_margin('|').rstrip
            |    $ bin spec-file create [NAME]
            |
            |      Creates a spec file called NAME
            |      and populates it with defaults.
        USAGE
      end

      it "uses the command's summary as fall-back for the description" do
        banner = Command::Banner.new(Fixture::Command::SpecFile::Lint::Repo)
        banner.send(:formatted_usage_description).should ==
          <<-USAGE.strip_margin('|').rstrip
            |    $ bin spec-file lint repo
            |
            |      Checks the validity of ALL specs in a repo.
        USAGE
      end

      it 'returns summaries of the subcommands of a command, sorted by name' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        banner.send(:formatted_subcommand_summaries).should ==
          <<-COMMANDS.strip_margin('|').rstrip
            |    * create   Creates a spec file stub.
            |    * lint     Checks the validity of a spec file.
        COMMANDS
      end

      it 'returns the options aligning the descriptions' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        banner.send(:formatted_options_description).should ==
          <<-OPTIONS.strip_margin('|').rstrip
           |    --verbose   Show more debugging information
           |    --no-ansi   Show output without ANSI codes
           |    --help      Show help banner of specified command
        OPTIONS

        banner = Command::Banner.new(Fixture::Command::SpecFile::Lint::Repo)
        banner.send(:formatted_options_description).should ==
          <<-OPTIONS.strip_margin('|').rstrip
            |    --only-errors   Skip warnings
            |    --verbose       Show more debugging information
            |    --no-ansi       Show output without ANSI codes
            |    --help          Show help banner of specified command
        OPTIONS
      end
    end

    #-------------------------------------------------------------------------#

  end
end
