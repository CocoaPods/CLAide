# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module CLAide
  describe Helper do

    before do
      @subject = Helper
    end

    describe '::terminal_width' do
      before do
        @subject.instance_variable_set(:@terminal_width, nil)
      end

      it 'returns the width of the terminal' do
        STDOUT.expects(:tty?).returns(true)
        Helper.expects(:system).with('which tput > /dev/null 2>&1').
          returns(true)
        Helper.expects(:`).with('tput cols').returns('80')
        @subject.terminal_width.should == 80
      end

      it 'is robust against the tput command not being available' do
        STDOUT.expects(:tty?).returns(true)
        Helper.expects(:system).with('which tput > /dev/null 2>&1').
          returns(false)
        @subject.terminal_width.should == 0
      end

      it 'is robust against the tput command not being available' do
        STDOUT.expects(:tty?).returns(false)
        @subject.terminal_width.should == 0
      end
    end

    describe '::format_markdown' do
      it 'wraps a string by paragraph' do
        @subject.stubs(:terminal_width).returns(20)
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
        @subject.format_markdown(string).should == result
      end

      it 'supports an optional indentation' do
        @subject.stubs(:terminal_width).returns(20)
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
        @subject.format_markdown(string, 2).should == result
      end

      it 'supports an optional indentation' do
        @subject.stubs(:terminal_width).returns(80)
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
        @subject.format_markdown(string, 0, 20).should == result
      end

      it 'preserves the line formatting of code paragraphs' do
        @subject.stubs(:terminal_width).returns(80)
        string = <<-DOC.strip_margin('|').rstrip
          |This is an example code block:
          |
          |    @subject.format_markdown(string, 0, 20)
        DOC
        result = <<-DOC.strip_margin('|').rstrip
          |This is an example
          |code block:
          |
          |    @subject.format_markdown(string, 0, 20)
        DOC
        @subject.format_markdown(string, 0, 20).should == result
      end
    end

    describe '::wrap_with_indent' do
      it 'wraps a string according to the terminal width' do
        @subject.stubs(:terminal_width).returns(10)
        string = '1234567890 1234567890'
        @subject.wrap_with_indent(string).should == "1234567890\n1234567890"
      end

      it 'indents the lines except the first' do
        @subject.stubs(:terminal_width).returns(10)
        string = '1234567890 1234567890'
        @subject.wrap_with_indent(string, 2).should ==
          "1234567890\n  1234567890"
      end

      it 'supports a maximum width' do
        @subject.stubs(:terminal_width).returns(20)
        string = '1234567890 1234567890'
        @subject.wrap_with_indent(string, 0, 10).should ==
          "1234567890\n1234567890"
      end

      it 'wraps to the maximum width if the terminal one is not available' do
        @subject.stubs(:terminal_width).returns(0)
        string = '1234567890 1234567890'
        @subject.wrap_with_indent(string, 0, 10).should ==
          "1234567890\n1234567890"
      end
    end

    describe '::word_wrap' do
      it 'wraps by word a string a string with the given width' do
        string = 'one two three four'
        @subject.word_wrap(string, 3).should == "one\ntwo\nthree\nfour"
      end
    end

    describe '::strip_heredoc' do
      it 'strips the smallest white space' do
        string = <<-DOC
            word 1
          word 2
        DOC
        @subject.strip_heredoc(string).should == "  word 1\nword 2\n"
      end

      it 'is robust against whitespace only strings' do
        string = "  \n"
        @subject.strip_heredoc(string).should == string
      end
    end

    describe '::levenshtein_distance' do
      it 'returns the distance among two strings' do
        @subject.levenshtein_distance('word 1', 'word 2').should == 1
        @subject.levenshtein_distance('word 1', 'dictionary').should == 9
      end
    end
  end
end
