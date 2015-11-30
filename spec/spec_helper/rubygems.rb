module SpecHelper
  module RubyGems
    module_function

    def fixture_spec_with_file(file)
      Gem::Specification.new do |s|
        s.name = 'fixture-demo-plugin'
        s.version = '1.0.0'
        s.files = [file.to_s]
        s.require_paths = ['']
        def s.full_gem_path
          File.expand_path('..', files.first)
        end
      end
    end

    def stub_latest_specs(specs)
      specs = Array(specs)
      Gem::Specification.expects(:latest_specs).at_least(0).returns(specs)
    end
  end
end
