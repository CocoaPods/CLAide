# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::Banner do
    describe 'in general' do
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

    describe 'banner components' do
      it "returns a usage description based on the command's description" do
        Helper.stubs(:terminal_width).returns(52)
        banner = Command::Banner.new(Fixture::Command::SpecFile::Create)
        banner.send(:formatted_usage_description).should ==
          <<-USAGE.strip_margin('|').rstrip
            |    $ bin spec-file create [NAME]
            |
            |      Creates a spec file called NAME and populates
            |      it with defaults.
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
            |    + create    Creates a spec file stub.
            |    + lint      Checks the validity of a spec file.
        COMMANDS
      end

      it 'returns the options' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        banner.send(:formatted_options_description).should ==
          <<-OPTIONS.strip_margin('|').rstrip
            |    --verbose   Show more debugging information
            |    --no-ansi   Show output without ANSI codes
            |    --help      Show help banner of specified command
        OPTIONS
      end

      it 'aligns the descriptions of the subcommands and of the options' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        result = banner.formatted_banner
        result.should.include('    + create    Creates a spec file stub.')
        result.should.include('    --verbose   Show more debugging')
      end

      it 'highlights the default subcommand' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:default_subcommand).returns('create')
        result = banner.formatted_banner
        result.should.include('> create    Creates a spec file stub')
        result.should.include('+ lint      Checks the validity of a spec file')
      end
    end

    describe 'banner command arguments' do
      it 'should correctly display required single argument' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('REQUIRED', true)])
        banner.send(:signature_arguments).should == 'REQUIRED'
      end

      it 'should correctly display required alternate arguments' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(REQ1 REQ2), true)])
        banner.send(:signature_arguments).should == 'REQ1|REQ2'
      end

      it 'should correctly display optional single argument' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('OPTIONAL', false)])
        banner.send(:signature_arguments).should == '[OPTIONAL]'
      end

      it 'should correctly display optional alternate arguments' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(OPT1 OPT2), false)])
        banner.send(:signature_arguments).should == '[OPT1|OPT2]'
      end

      it 'should correctly display required, repeatable single argument' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('REQUIRED', true, true)])
        banner.send(:signature_arguments).should == 'REQUIRED ...'
      end

      it 'should correctly display required, repeatable alternate arguments' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(REQ1 REQ2), true, true)])
        banner.send(:signature_arguments).should == 'REQ1|REQ2 ...'
      end

      it 'should correctly display optional, repeatable single argument' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('OPTIONAL', false, true)])
        banner.send(:signature_arguments).should == '[OPTIONAL ...]'
      end

      it 'should correctly display optional, repeatable alternate arguments' do
        banner = Command::Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(OPT1 OPT2), false, true)])
        banner.send(:signature_arguments).should == '[OPT1|OPT2 ...]'
      end
    end
  end
end
