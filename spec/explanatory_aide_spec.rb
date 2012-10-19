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

  #it "returns a flag and deletes it" do
    #@argv.flag?('flag').should == true
    #@argv.flag?('other-flag').should == false
    #@argv.flag?('option').should == nil
    #@argv.should == %w{ --option VALUE ARG1 ARG2 }
  #end
end
