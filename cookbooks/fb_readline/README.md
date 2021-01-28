fb_input Cookbook
====================
This cookbook manages configuration for GNU Readline library.

Requirements
------------

Attributes
----------
* node['fb_readline']['config']['key_bindings'][$KEY][$VALUE]
* node['fb_readline']['config']['variables'][$KEY][$VALUE]
* node['fb_readline']['config']['mode'][$MODE]['key_bindings'][$KEY][$VALUE]
* node['fb_readline']['config']['mode'][$MODE]['variables'][$KEY][$VALUE]
* node['fb_readline']['config']['term'][$TERM]['key_bindings'][$KEY][$VALUE]
* node['fb_readline']['config']['term'][$TERM]['variables'][$KEY][$VALUE]

Usage
-----
Include `fb_readline` to manage `/etc/inputrc` for Readline. Variables and key
bindings can be modified by setting the corresponding attributes, e.g.:

```ruby
node.default['fb_readline']['config']['variables']['silence_bell'] = true
```

These can also be set on a per-editor mode (`vi`, `emacs`) or terminal
emulator basis via the `node['fb_readline']['config']['mode']` and
`node['fb_readline']['config']['term']` attributes. Refer to the
[upstream documentation](https://tiswww.case.edu/php/chet/readline/readline.html#SEC9)
for information on the available settings and their usage.
