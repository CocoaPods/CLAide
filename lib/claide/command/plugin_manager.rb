# encoding: utf-8

module CLAide
  class Command
    # Handles plugin related logic logic for the `Command` class.
    #
    # Plugins are loaded the first time a command run and are identified by the
    # prefix specified in the command class. Plugins must adopt the following
    # conventions:
    #
    # - Support being loaded by a file located under the
    # `lib/#{plugin_prefix}_plugin` relative path.
    # - Be stored in a folder named after the plugin.
    #
    class PluginManager
      # @return [Hash<String,Gem::Specification>] The loaded plugins,
      #         grouped by plugin prefix.
      #
      def self.loaded_plugins
        @loaded_plugins ||= {}
      end

      # @return [Array<Gem::Specification>] Loads plugins via RubyGems looking
      #         for files named after the `PLUGIN_PREFIX_plugin` and returns the
      #         specifications of the gems loaded successfully.
      #         Plugins are required safely.
      #
      def self.load_plugins(plugin_prefix)
        loaded_plugins[plugin_prefix] ||=
          plugin_gems_for_prefix(plugin_prefix).map do |spec, paths|
            spec if safe_activate_and_require(spec, paths)
          end.compact
      end

      # @return [Array<[Gem::Specification, Array<String>]>]
      #         Returns an array of tuples containing the specifications and
      #         plugin files to require for a given plugin prefix.
      #
      def self.plugin_gems_for_prefix(prefix)
        glob = "#{prefix}_plugin#{Gem.suffix_pattern}"
        Gem::Specification.latest_specs(true).map do |spec|
          matches = spec.matches_for_glob(glob)
          [spec, matches] unless matches.empty?
        end.compact
      end

      # @return [Array<Specification>] The RubyGems specifications for the
      #         loaded plugins.
      #
      def self.specifications
        loaded_plugins.values.flatten.uniq
      end

      # @return [Array<String>] The list of the plugins whose root path appears
      #         in the backtrace of an exception.
      #
      # @param  [Exception] exception
      #         The exception to analyze.
      #
      def self.plugins_involved_in_exception(exception)
        loaded_plugins.values.flatten.select do |gemspec|
          exception.backtrace.any? do |line|
            gemspec.full_require_paths.any? do |plugin_path|
              line.include?(plugin_path)
            end
          end
        end.uniq.map(&:name)
      end

      # Loads the given path. If any exception occurs it is catched and an
      # informative message is printed.
      #
      # @param  [String] path
      #         The path to load
      #
      # rubocop:disable RescueException
      def self.safe_activate_and_require(spec, paths)
        spec.activate
        paths.each { |path| require(path) }
        true
      rescue Exception => exception
        message = "\n---------------------------------------------"
        message << "\nError loading the plugin `#{spec.full_name}`.\n"
        message << "\n#{exception.class} - #{exception.message}"
        message << "\n#{exception.backtrace.join("\n")}"
        message << "\n---------------------------------------------\n"
        warn message.ansi.yellow
        false
      end
      # rubocop:enable RescueException

      # Executes the given block while silencing the given streams.
      #
      # @return [Object] The value of the given block.
      #
      # @param [Array] streams
      #                The streams to silence.
      #
      # @note credit to DHH http://stackoverflow.com/a/8959520
      #
      def self.silence_streams(*streams)
        on_hold = streams.map(&:dup)
        streams.each do |stream|
          stream.reopen('/dev/null')
          stream.sync = true
        end
        yield
      ensure
        streams.each_with_index do |stream, i|
          stream.reopen(on_hold[i])
        end
      end
    end
  end
end
