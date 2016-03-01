# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

class CLAide::Command
  describe Banner do
    describe 'in general' do
      it 'combines the summary/description, commands, and options' do
        banner = Banner.new(Fixture::Command::SpecFile::Create)
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
        Banner::TextWrapper.stubs(:terminal_width).returns(52)
        banner = Banner.new(Fixture::Command::SpecFile::Create)
        banner.send(:formatted_usage_description).should ==
          <<-USAGE.strip_margin('|').rstrip
            |    $ bin spec-file create [NAME]
            |
            |      Creates a spec file called NAME and populates
            |      it with defaults.
        USAGE
      end

      it "uses the command's summary as fall-back for the description" do
        banner = Banner.new(Fixture::Command::SpecFile::Lint::Repo)
        banner.send(:formatted_usage_description).should ==
          <<-USAGE.strip_margin('|').rstrip
            |    $ bin spec-file lint repo
            |
            |      Checks the validity of ALL specs in a repo.
        USAGE
      end

      it 'returns summaries of the subcommands of a command, sorted by name' do
        banner = Banner.new(Fixture::Command::SpecFile)
        banner.send(:formatted_subcommand_summaries).should ==
          <<-COMMANDS.strip_margin('|').rstrip
            |    + create    Creates a spec file stub.
            |    + lint      Checks the validity of a spec file.
        COMMANDS
      end

      it 'returns the options' do
        banner = Banner.new(Fixture::Command::SpecFile)
        banner.send(:formatted_options_description).should ==
          <<-OPTIONS.strip_margin('|').rstrip
            |    --verbose   Show more debugging information
            |    --no-ansi   Show output without ANSI codes
            |    --help      Show help banner of specified command
        OPTIONS
      end

      it 'aligns the descriptions of the subcommands and of the options' do
        banner = Banner.new(Fixture::Command::SpecFile)
        result = banner.formatted_banner
        result.should.include('    + create    Creates a spec file stub.')
        result.should.include('    --verbose   Show more debugging')
      end

      it 'highlights the default subcommand' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:default_subcommand).returns('create')
        result = banner.formatted_banner
        result.should.include('> create    Creates a spec file stub')
        result.should.include('+ lint      Checks the validity of a spec file')
      end
    end

    describe 'banner command arguments' do
      it 'should correctly display required single argument' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('REQUIRED', true)])
        banner.send(:signature_arguments).should == 'REQUIRED'
      end

      it 'should correctly display required alternate arguments' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(REQ1 REQ2), true)])
        banner.send(:signature_arguments).should == 'REQ1|REQ2'
      end

      it 'should correctly display optional single argument' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('OPTIONAL', false)])
        banner.send(:signature_arguments).should == '[OPTIONAL]'
      end

      it 'should correctly display optional alternate arguments' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(OPT1 OPT2), false)])
        banner.send(:signature_arguments).should == '[OPT1|OPT2]'
      end

      it 'should correctly display required, repeatable single argument' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('REQUIRED', true, true)])
        banner.send(:signature_arguments).should == 'REQUIRED ...'
      end

      it 'should correctly display required, repeatable alternate arguments' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(REQ1 REQ2), true, true)])
        banner.send(:signature_arguments).should == 'REQ1|REQ2 ...'
      end

      it 'should correctly display optional, repeatable single argument' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new('OPTIONAL', false, true)])
        banner.send(:signature_arguments).should == '[OPTIONAL ...]'
      end

      it 'should correctly display optional, repeatable alternate arguments' do
        banner = Banner.new(Fixture::Command::SpecFile)
        Fixture::Command::SpecFile.stubs(:arguments).
          returns([CLAide::Argument.new(%w(OPT1 OPT2), false, true)])
        banner.send(:signature_arguments).should == '[OPT1|OPT2 ...]'
      end
    end
  end

  class Banner
    describe TextWrapper do
      describe '::terminal_width' do
        before do
          TextWrapper.instance_variable_set(:@terminal_width, nil)
        end

        it 'returns the width of the terminal' do
          STDOUT.expects(:tty?).returns(true)
          STDOUT.expects(:winsize).returns([20, 80])
          TextWrapper.terminal_width.should == 80
        end

        it 'is robust against not being a tty' do
          STDOUT.expects(:tty?).returns(false)
          TextWrapper.terminal_width.should == 0
        end
      end

      describe '::wrap_formatted_text' do
        it 'wraps a string by paragraph' do
          TextWrapper.stubs(:terminal_width).returns(20)
          string = <<-DOC.strip_margin('|').rstrip
            |Downloads all dependencies defined
            |in `Podfile` and creates an Xcode Pods
            |library project in `./Pods`.
            |
            |The Xcode project file should be specified
            |in your `Podfile` like this:
          DOC
          result = <<-DOC.strip_margin('|').rstrip
            |Downloads all
            |dependencies defined
            |in `Podfile` and
            |creates an Xcode
            |Pods library project
            |in `./Pods`.
            |
            |The Xcode project
            |file should be
            |specified in your
            |`Podfile` like this:
          DOC
          TextWrapper.wrap_formatted_text(string).should == result
        end

        it 'supports an optional indentation' do
          TextWrapper.stubs(:terminal_width).returns(20)
          string = <<-DOC.strip_margin('|').rstrip
            |Downloads all dependencies defined
            |in `Podfile` and creates an Xcode Pods
            |library project in `./Pods`.
          DOC
          result = <<-DOC.strip_margin('|').rstrip
            |  Downloads all
            |  dependencies
            |  defined in
            |  `Podfile` and
            |  creates an Xcode
            |  Pods library
            |  project in
            |  `./Pods`.
          DOC
          TextWrapper.wrap_formatted_text(string, 2).should == result
        end

        it 'supports an optional indentation' do
          TextWrapper.stubs(:terminal_width).returns(80)
          string = <<-DOC.strip_margin('|').rstrip
            |Downloads all dependencies defined
            |in `Podfile` and creates an Xcode Pods
            |library project in `./Pods`.
          DOC
          result = <<-DOC.strip_margin('|').rstrip
            |Downloads all
            |dependencies defined
            |in `Podfile` and
            |creates an Xcode
            |Pods library project
            |in `./Pods`.
          DOC
          TextWrapper.wrap_formatted_text(string, 0, 20).should == result
        end

        it 'preserves the line formatting of code paragraphs' do
          TextWrapper.stubs(:terminal_width).returns(80)
          string = <<-DOC.strip_margin('|').rstrip
            |This is an example code block:
            |
            |    TextWrapper.wrap_formatted_text(string, 0, 20)
          DOC
          result = <<-DOC.strip_margin('|').rstrip
            |This is an example
            |code block:
            |
            |    TextWrapper.wrap_formatted_text(string, 0, 20)
          DOC
          TextWrapper.wrap_formatted_text(string, 0, 20).should == result
        end

        # rubocop:disable all
        it 'handles multi-line code blocks regarding indentation' do
          string = <<-DOC.strip_margin('|').rstrip
            |Examples:
            |
            |    $ pod trunk register eloy@example.com 'Eloy Durán' --description='Personal Laptop'
            |    $ pod trunk register eloy@example.com --description='Work Laptop'
            |    $ pod trunk register eloy@example.com
            |
          DOC
          result = <<-DOC.strip_margin('|').rstrip
            |  Examples:
            |
            |      $ pod trunk register eloy@example.com 'Eloy Durán' --description='Personal Laptop'
            |      $ pod trunk register eloy@example.com --description='Work Laptop'
            |      $ pod trunk register eloy@example.com
          DOC
          TextWrapper.wrap_formatted_text(string, 2, 20).should == result
        end
        # rubocop:enable all
      end

      describe '::wrap_with_indent' do
        it 'wraps a string according to the terminal width' do
          TextWrapper.stubs(:terminal_width).returns(5)
          string = '12345 12345'
          TextWrapper.wrap_with_indent(string).should == "12345\n12345"
        end

        it 'indents the lines except the first' do
          TextWrapper.stubs(:terminal_width).returns(5)
          string = '12345 12345'
          TextWrapper.wrap_with_indent(string, 2).should == "12345\n  12345"
        end

        it 'supports a maximum width' do
          TextWrapper.stubs(:terminal_width).returns(10)
          string = '12345 12345'
          TextWrapper.wrap_with_indent(string, 0, 5).should == "12345\n12345"
        end

        it 'wraps to the maximum width if the terminal one is not available' do
          TextWrapper.stubs(:terminal_width).returns(0)
          string = '12345 12345'
          TextWrapper.wrap_with_indent(string, 0, 5).should == "12345\n12345"
        end
      end

      describe '::word_wrap' do
        it 'wraps by word a string a string with the given width' do
          string = 'one two three four'
          TextWrapper.word_wrap(string, 3).should == "one\ntwo\nthree\nfour"
        end
      end

      describe '::strip_heredoc' do
        it 'strips the smallest white space' do
          string = <<-DOC
              word 1
            word 2
          DOC
          TextWrapper.strip_heredoc(string).should == "  word 1\nword 2\n"
        end

        it 'is robust against whitespace only strings' do
          string = "  \n"
          TextWrapper.strip_heredoc(string).should == string
        end
      end
    end
  end
end
