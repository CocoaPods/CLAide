# Hi, I’m Claide, your friendly command-line tool aide.

I was born out of a need for a ‘simple’ option and command parser by the
[CocoaPods][CocoaPods] project, while providing an API that allows you to
quickly create a full featured command-line interface.


## Usage

### Argument handling

At the core, a library such as myself needs to parse the arguments specified by
the user. There are three types that can be specified:

| `--milk`, `--no-milk` | A boolean ‘flag’, which may be negated.             |
| `--sweetner=honey`    | An ‘option’ that consists of a key and a value and
                          **MUST** be separated by an equals sign ‘=’.        |
| `tea`                 | An ‘argument’ which may be interpreted as a command
                          or a command’s argument.                            |

Working with arguments is done through the `CLAide::ARGV` class:

```ruby
require 'claide'

argv = CLAide::ARGV.new(['tea', '--no-milk', '--sweetner=honey'])
p argv.arguments          # => ['tea']
p argv.shift_argument     # => 'tea'
p argv.flag?('milk')      # => false
p argv.option('sweetner') # => 'honey'
```

NOTE: _Except for `arguments`, all of the above methods remove the entries from
      the remaining entries._

In case the requested ‘flag’ or ‘option’ is not present, `nil` is returned. You
can specify a default value to be used as the optional second argument:

```ruby
require 'claide'

argv = CLAide::ARGV.new(['tea'])
p argv.flag?('milk', true)         # => true
p argv.option('sweetner', 'sugar') # => 'sugar'
```


### Exception handling

I’m a tad cheeky; I use exceptions for some control flow. In case a command or
option is unrecognized (or any of your own validations fail) a `Help` exception
is raised, which signals to me that the user should see a help banner.

The `Help` exception class includes the `InformativeError` module, which means
that, unless the user specifies the `--verbose` option, the backtrace of the
exception is not shown. If your application needs the same behavior, for
instance when a required file doesn’t exist, you can get that by including the
`InformativeError` module into your exception class as well. The module also
allows you to specify an explicit exit status code.

Any other exception is re-raised as-is, or can be reported in a custom way, as
can be seen in [CocoaPods][repor-error].


### Command handling

Commands are actions that a tool can perform. Every command is represented by
its own command class.

Commands may be nested, in which case they inherit from the ‘super command’
class. Some of these nested commands may not actually perform any work work
themselves, but are rather used as ‘super commands’ only, in which case they
are ‘abtract commands’.

See the example for a simple illustration on how to define commands.

Unless you load ActiveSupport’s string extensions, or define the required
string methods in any other way, you wil have to override the `command` class
method of a command class to return a proper name. For example:

```ruby
class SpecFile
  def self.command
    'spec-file'
  end
end
```



[CocoaPods]: https://github.com/CocoaPods/CocoaPods
[report-error]: https://github.com/CocoaPods/CocoaPods/blob/054fe5c861d932219ec40a91c0439a7cfc3a420c/lib/cocoapods/command.rb#L36
