## 0.5.0

###### Enhancements

* Add a `ignore_in_command_lookup` option to commands, which makes it possible
  to have anonymous command classes that are or only meant to provide common
  functionality, but are otherwise completely ignored during parsing, command
  lookup, and help banner printing.  
  [Eloy Durán](https://github.com/alloy)

* Deprecate the `color` option in favor of `ansi`. This is more abstract and
  can be used for commands that only prettify output by using, for instance,
  the bold ANSI code. This applies to the `CLAide` APIs as well.  
  [Eloy Durán](https://github.com/alloy)

* Add more hooks that allow the user to customize how to prettify output.  
  [Eloy Durán](https://github.com/alloy)

* Word wrap option descriptions to terminal width.  
  [Eloy Durán](https://github.com/alloy)
  [#6](https://github.com/CocoaPods/CLAide/issues/6)


## 0.4.0

###### Enhancements

* Added support for plugins.  
  [Les Hill](https://github.com/leshill)
  [#1](https://github.com/CocoaPods/CLAide/pull/1)

