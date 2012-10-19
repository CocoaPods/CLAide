require 'bacon'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'explanatory_aide'

describe ExplanatoryAide::ARGV do
  before do
    @argv = ExplanatoryAide::ARGV.new(%w{ --flag --option VALUE ARG1 ARG2 --no-other-flag })
  end

  it "returns the options as a hash" do
    @argv.options.should == {
      'flag' => true,
      'other-flag' => false,
      'option' => 'VALUE'
    }
  end

  it "returns the arguments" do
    @argv.arguments.should == %w{ ARG1 ARG2 }
  end

  it "returns a flag and deletes it" do
    @argv.flag?('flag').should == true
    @argv.flag?('other-flag').should == false
    @argv.flag?('option').should == nil
    @argv.remainder.should == %w{ --option VALUE ARG1 ARG2 }
  end

  it "returns an option and deletes it" do
    @argv.option('flag').should == nil
    @argv.option('other-flag').should == nil
    @argv.option('option').should == 'VALUE'
    @argv.remainder.should == %w{ --flag ARG1 ARG2 --no-other-flag }
  end

  it "returns the first argument and deletes it" do
    @argv.shift_argument.should == 'ARG1'
    @argv.remainder.should == %w{ --flag --option VALUE ARG2 --no-other-flag }
  end
end
