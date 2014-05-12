# encoding: utf-8

module CLAide
  class Command
    module PluginsHelper
      # Loads additional plugins via rubygems looking for files named after the
      # `PLUGIN_PREFIX_plugin`.
      #
      def self.load_plugins(plugin_prefix)
        paths = PluginsHelper.plugin_load_paths(plugin_prefix)
        loaded_paths = []
        paths.each do |path|
          if PluginsHelper.safe_require(path)
            loaded_paths << path
          end
        end
        loaded_paths
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
        if gemspec = find_gemspec(path)
          spec = Gem::Specification.load(gemspec)
        end

        if spec
          "#{spec.name}: #{spec.version}"
        else
          "[!] Unable to load a specification for `#{path}`"
        end
      end

      # @return [String] Finds the path of the gemspec of a path. The path is
      # iterated upwards until a dir with a single gemspec is found.
      #
      # @param  [String] path
      #         The load path of a plugin.
      #
      def self.find_gemspec(path)
        reverse_ascending_paths(path).find do |candidate_path|
          glob = Dir.glob("#{candidate_path}/*.gemspec")
          if glob.count == 1
            return glob.first
          end
        end
        nil
      end

      # @return [String] Returns the list of the parents paths of a path.
      #
      # @param  [String] path
      #         The path for which the list is needed.
      #
      def self.reverse_ascending_paths(path)
        components = path.split('/')[0...-1]
        progress = nil
        components.map do |component|
          if progress
            progress = progress + '/' + component
          else
            progress = component
          end
        end.reverse
      end

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

      # Loads the given path. If any exception occurs it is catched and an
      # informative message is printed.
      #
      # @param  [String] path
      #         The path to load
      #
      # rubocop:disable RescueException
      def self.safe_require(path)
        require path
        true
      rescue Exception => exception
        message = "\n---------------------------------------------"
        message << "\nError loading the plugin with path `#{path}`.\n"
        message << "\n#{exception.class} - #{exception.message}"
        message << "\n#{exception.backtrace.join("\n")}"
        message << "\n---------------------------------------------\n"
        puts message.ansi.yellow
        false
      end
      # rubocop:enable RescueException
    end
  end
end
