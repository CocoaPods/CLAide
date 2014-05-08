module CLAide
  class Command
    module ShellCompletionHelper
      # Generates a completion script for the Z shell.
      #
      module ZSHCompletionGenerator

        # @return [String] The completion script.
        #
        # @param  [Class] command
        #         The command to generate the script for.
        #
        def self.generate(command)
          result = <<-DOC
#compdef #{command.command}
# setopt XTRACE VERBOSE
# vim: ft=zsh sw=2 ts=2 et

local -a _subcommands
local -a _options

#{case_statement_fragment(command)}
          DOC
          result.gsub(/\n *\n/, "\n\n")
        end

        # Returns a case statement for a given command with the given nesting
        # level.
        #
        # @param  [Class] command
        #         The command to generate the fragment for.
        #
        # @param  [Fixnum] nesting_level
        #         The nesting level to detect the index of the words array.
        #
        # @return [String] the case statement fragment.
        #
        # @example
        #   case "$words[2]" in
        #     spec-file)
        #       [..snip..]
        #     ;;
        #     *) # bin
        #       _subcommands=(
        #         "spec-file:"
        #       )
        #       _describe -t commands "bin subcommands" _subcommands
        #       _options=(
        #         "--completion-script:Print the auto-completion script"
        #         "--help:Show help banner of specified command"
        #         "--verbose:Show more debugging information"
        #         "--version:Show the version of the tool"
        #       )
        #       _describe -t options "bin options" _options
        #     ;;
        #   esac
        #
        def self.case_statement_fragment(command, nest_level = 0)
          entries = case_statement_entries_fragment(command, nest_level+1)
          subcommands = subcommands_fragment(command)
          options = options_fragment(command)

          result = <<-DOC
case "$words[#{nest_level + 2}]" in
  #{ShellCompletionHelper.indent(entries,1)}
  *) # #{command.full_command}
    #{ShellCompletionHelper.indent(subcommands, 2)}
    #{ShellCompletionHelper.indent(options, 2)}
  ;;
esac
          DOC
          result.gsub(/\n *\n/, "\n").chomp
        end

        # Returns a case statement for a given command with the given nesting
        # level.
        #
        # @param  [Class] command
        #         The command to generate the fragment for.
        #
        # @param  [Fixnum] nesting_level
        #         The nesting level to detect the index of the words array.
        #
        # @return [String] the case statement fragment.
        #
        # @example
        #   repo)
        #     case "$words[5]" in
        #       *) # bin spec-file lint repo
        #         _options=(
        #           "--help:Show help banner of specified command"
        #           "--only-errors:Skip warnings"
        #           "--verbose:Show more debugging information"
        #         )
        #         _describe -t options "bin spec-file lint repo options" _options
        #       ;;
        #     esac
        #   ;;
        #
        def self.case_statement_entries_fragment(command, nest_level)
          subcommands = command.subcommands_for_command_lookup
          result = subcommands.sort_by(&:name).map do |subcommand|
            subcase = case_statement_fragment(subcommand, nest_level)
            value = <<-DOC
#{subcommand.command})
  #{ShellCompletionHelper.indent(subcase, 1)}
;;
            DOC
          end.join("\n")
        end

        # Returns the fragment of the subcommands array.
        #
        # @param  [Class] command
        #         The command to generate the fragment for.
        #
        # @return [String] The fragment.
        #
        def self.subcommands_fragment(command)
          if subcommands_list = subcommands_completions(command)
            <<-DOC
_subcommands=(
  #{ShellCompletionHelper.indent(subcommands_list.join("\n"), 1)}
)
_describe -t commands "#{command.full_command} subcommands" _subcommands
            DOC
          else
            ''
            end
        end


        # Returns the fragment of the entries of the subcommands array.
        #
        # @param  [Class] command
        #         The command to generate the fragment for.
        #
        # @return [Array<String>] The entries.
        #
        def self.subcommands_completions(command)
          subcommands = command.subcommands_for_command_lookup
          unless subcommands.empty?
            subcommands.sort_by(&:name).map do |subcommand|
              "\"#{subcommand.command}:#{subcommand.summary}\""
            end
          end
        end

        # Returns the fragment of the options array.
        #
        # @param  [Class] command
        #         The command to generate the fragment for.
        #
        # @return [String] The fragment.
        #
        def self.options_fragment(command)
          if options_list = option_completions(command)
            <<-DOC
_options=(
  #{ShellCompletionHelper.indent(options_list.join("\n"), 1)}
)
_describe -t options "#{command.full_command} options" _options
            DOC
          else
            ''
            end
        end

        # Returns the fragment of the entries of the options array.
        #
        # @param  [Class] command
        #         The command to generate the fragment for.
        #
        # @return [Array<String>] The entries.
        #
        def self.option_completions(command)
          options = command.options
          unless options.empty?
            options.sort_by(&:first).map do |option|
              "\"#{option[0]}:#{option[1]}\""
            end
          end
        end
      end
    end
  end
end
