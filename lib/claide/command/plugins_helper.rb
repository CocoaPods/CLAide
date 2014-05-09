# encoding: utf-8

module CLAide
  class Command
    module PluginsHelper
      # Returns the paths of the files to require to load the available
      # plugins.
      #
      # @return [Array] The found plugins load paths.
      #
      def self.plugin_load_paths(plugin_prefix)
        if plugin_prefix && !plugin_prefix.empty?
          if Gem.respond_to? :find_latest_files
            Gem.find_latest_files("#{plugin_prefix}_plugin")
          else
            Gem.find_files("#{plugin_prefix}_plugin")
          end
        else
          []
        end
      end

      # Returns the name and the version of the plugin with the given path.
      #
      # @param  [String] path
      #         The load path of the plugin.
      #
      # @return [String] A string including the name and the version or a
      #         failure message.
      #
      def self.plugin_info(path)
        components = path.split('/')
        progress = ''
        paths = components.map do |component|
          progress = progress + '/' + component
        end

        gemspec = nil
        paths.reverse.find do |candidate_path|
          glob = Dir.glob("#{candidate_path}/*.gemspec")
          if glob.count == 1
            gemspec = glob.first
            break
          end
        end

        spec = Gem::Specification.load(gemspec)
        if spec
          "#{spec.name}: #{spec.version}"
        else
          "[!] Unable to load a specification for `#{path}`"
        end
      end
    end
  end
end
