# encoding: utf-8

require File.expand_path('../../spec_helper', __FILE__)

module CLAide
  describe Command::Parser do
    before do
      @subject = Command::Parser
    end

    describe '::parse' do
      before do
        @command_class = Fixture::Command::SpecFile.dup
      end

      it 'tries to match a subclass for each of the subcommands' do
        parsed = @subject.parse(Fixture::Command, %w(spec-file --verbose lint))
        parsed.should.be.instance_of Fixture::Command::SpecFile::Lint
      end

      it 'invokes the default subcommand only if abstract' do
        @command_class.default_subcommand = 'lint'
        @command_class.abstract_command = false
        cmd = @subject.parse(@command_class, ([]))
        cmd.class.should == @command_class
      end

      it "doesn't return a default subcommand if a command is given" do
        @command_class.default_subcommand = 'lint'
        cmd = @subject.parse(@command_class, (%w(create)))
        cmd.class.should == Fixture::Command::SpecFile::Create
      end

      it "doesn't invoke a default subcommand by default" do
        @command_class.default_subcommand = nil
        cmd = @subject.parse(@command_class, ([]))
        cmd.class.should == @command_class
      end
    end

    describe '::load_default_subcommand' do
      before do
        @command_class = Fixture::Command::SpecFile.dup
        @command_class.default_subcommand = 'lint'
      end

      it 'returns the default subcommand if specified' do
        cmd = @subject.load_default_subcommand(@command_class, ([]))
        cmd.class.should == Fixture::Command::SpecFile::Lint
      end

      it 'raises if unable to find the default subcommand' do
        @command_class.default_subcommand = 'find-me'
        should.raise do
          @subject.load_default_subcommand(@command_class, [])
        end.message.should.match /Unable to find the default subcommand/
      end

      it 'marks the command as invoked by default' do
        cmd = @subject.load_default_subcommand(@command_class, ([]))
        cmd.invoked_as_default.should.be.true
      end
    end
  end
end
