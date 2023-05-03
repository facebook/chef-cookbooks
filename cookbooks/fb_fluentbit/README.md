fb_fluentbit Cookbook
========================
This cookbook installs the Fluent Bit daemon and optionally plugins for it.

Attributes
----------
* node['fb_fluentbit']['service_config']
* node['fb_fluentbit']['parser']
* node['fb_fluentbit']['input']
* node['fb_fluentbit']['filter']
* node['fb_fluentbit']['output']
* node['fb_fluentbit']['external']
* node['fb_fluentbit']['external_config_url']
* node['fb_fluentbit']['manage_packages']
* node['fb_fluentbit']['plugin_manage_packages']
* node['fb_fluentbit']['windows_package']

Usage
-----
Include `fb_fluentbit::default` recipe to setup fluentbit. For more
information about how to configure Fluent Bit, please refer to
[the documentation](https://docs.fluentbit.io/manual/)

This cookbook provides 2 options to create fluentbit config:
* Fetching existing config from url
* Configuration template

Fluentbit allows you to have multiple instances of the same plugins, for example
multiple tail plugin instances to get logs from multiple files.

Fluentbit supports built-in and external plugins.

### Supported Platforms
* RHEL
* Windows

### Upgrade to fluent-bit package/service/directory name
FluentBit moved from `td-agent-bit` naming starting with [v1.9.9](https://docs.fluentbit.io/manual/installation/upgrade-notes#fluent-bit-v1.9.9).
If your tier uses FluentBit you can upgrade and continue using this cookbook
by setting:
`node.default['fb_fluentbit']['adopt_package_name_fluent-bi'] = true`

**Important dates for this**
- October 2nd, 2023 fb_fluentbit will adopt the `fluent-bit` name by default
- April 15th, 2024 support of the `td-agen-bit` name will be dropped

### Install FluentBit
The package installation of FluentBit is managed through defining:
`node.default['fb_fluentbit']['manage_packages'] = true`

The purpose of this variable is to allow consumers to install their specific
package on their own cookbook if they want to bypass the default version.

### Fetching remote config
This cookbook can configure fluentbit to fetch its config from a remote
location. To do so, set `node['fb_fluentbit']['external_config_url']` to the
address at which to receive a custom config.

When operating in this mode, this completely bypasses any other node attributes
set on this cookbook.

### Configuring builtin plugins
Fluentbit comes with a number of different builtin plugins that can be
configured via the cookbook API. Each plugin is scoped by a key name (that is
not used in the final config file).

As an example, the following configures an input tailing a log file, filtering
out certain lines based on grep, and ultimately logging to stdout.

```
# Read lines from /var/log/my_log.txt
node.default['fb_fluentbit']['input']['tail']['tail_myfile'] = {
  'Path' => '/var/log/my_log.txt',
  'Tag' => 'my_cool_log',
  'db' => '/var/fluent-bit/my_log.db'
}

# Filter out lines that contain "badstuff"
node.default['fb_fluentbit']['filter']['grep']['filter_badstuff'] = {
  'Match' => 'my_cool_log',
  'Regex' => '^.+badstuff.+$',
}

# Finally, output to stdout
node.default['fb_fluentbit']['output']['stdout']['print_to_output'] = {
  'Match' => 'my_cool_log',
}
```

This will be rendered as:

```
[INPUT]
    Name tail
    Path /var/log/my_log.txt
    Tag my_cool_log
    db /var/fluent-bit/my_log.db

[FILTER]
    Name grep
    Match my_cool_log
    Regex ^.+badstuff.+$

[OUTPUT]
    Name stdout
    Match my_cool_log
```

### Runtime State
Some plugins have runtime state. For example the tail plugin should be
configured to save the state of the tracked file across service restarts. This
state is stored in a sqlite db file at a path provided in the INPUT config.
The directory `/var/fluent-bit/` (or `\ProgramData\fluent-bit\` in windows)  is
maintained as a central location for such files.

### External plugins
Fluent Bit supports external/custom plugins. This cookbook API allows for
providing a combination of RPM package name and plugin path like so:

```
# Tell fb_fluentbit where and how to configure your plugin.
node.default['fb_fluentbit']['external']['my_plugin'] = {
  'package' => 'my-rpm-package',
  'path' => '/usr/local/lib/my_plugin/my_plugin.so',
}
```

Or if the package distributes multiple plugins you can define all
paths through a list as:

```
node.default['fb_fluentbit']['external']['my_plugin'] = {
  'package' => 'my-rpm-package',
  'path' => ['/usr/local/lib/my_plugin/my_plugin.so',
    '/usr/local/lib/my_plugin/second_plugin.so'
  ],
}
```

You must include the package name as shown here and by default that package
will be installed and upgraded to the latest available version. If you need
to control the version explicitly, you can disable package installation by
setting `node.default['fb_fluentbit']['manage_packages'] = false` and
installing the package yourself, but the package name is still required.

Then configure your plugin just like any other builtin plugin:

```
node.default['fb_fluentbit']['output']['my_plugin']['foo'] = {
  'Match' => '*',
  'Key_1' => 'Value_1',
}
```

### Custom Parsers
Parsers can be configured by setting their name and configuration in
`node['fb_fluentbit']['parser']` like so:

```
node.default['fb_fluentbit']['parser']['some_parser'] = {
  'format' => 'json',
  'Time_Key' => 'time',
  'Time_Format' => '%Y-%m-%dT%H:%M:%S %z',
}
```

This will be rendered in parsers.conf as:

```
[PARSER]
    Name some_parser
    Format json
    Time_Key time
    Time_Format %Y-%m-%dT%H:%M:%S %z
```

### Custom Multiline Parsers
Parsers can be configured by setting their name and configuration in
`node['fb_fluentbit']['multiline_parser']` like so:

```
node.default['fb_fluentbit']['multiline_parser']['multiline-choco'] = {
  'name' => 'multiline-choco',
  'type' => 'regex',
  'flush_timeout' => '1000',
  "rules" => [
    {
      "state_name" => "start_state",
      "pattern" => "/^(?<time>\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2},\d+) (?<thread>\d+) \[(?<log_level>(DEBUG|INFO |WARN |ERROR))\].*$/",
      "next_state" => "cont",
    },
    {
      "state_name" => "cont",
      "pattern" => "/^(?!\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2},\d+).*/",
      "next_state" => "cont",
    },
  ],
}
```

Rules must be ordered and "start_state" MUST be the name of the first rule.
See https://docs.fluentbit.io/manual/v/1.9-pre/administration/configuring-fluent-bit/multiline-parsing#rules-definition

This will be rendered in parsers.conf as:

```
[MULTILINE_PARSER]
    name  multiline-choco
    type  regex
    flush_timeout  1000
    rule  "start_state"  "/^(?<time>\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2},\d+) (?<thread>\d+) \[(?<log_level>(DEBUG|INFO |WARN |ERROR))\].*$/"  "cont"
    rule  "cont"  "/^(?!\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2},\d+).*/"  "cont"
```

### Custom Service Restart Command (Windows)
Upon a FluentBit configuration change, the cookbook restarts the service to load
updated configuration.

If a custom command or script is required to restart the FluentBit service on
Windows, it can be configured in `node['fb_fluentbit']['custom_svc_restart_command']`
like so:

```
restart_command = 'powershell.exe -File C:\restart-script.ps1'
node.default['fb_fluentbit']['custom_svc_restart_command'] = restart_command
```

### Windows Service Enforcement
To ensure the service is active and enabled (set to Automatic) on Windows,
it can be configured with `node.default['fb_fluentbit']['keep_alive'] = true`
