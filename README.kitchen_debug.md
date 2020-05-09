# Debugging kitchen runs

You can setup kitchen using the same commands as in `.travis.yml`, but once
Chef runs you won't have access to connect, so modify
`fb_sudo/attributes/default.rb` and uncomment the kitchen block.

Then you can do `bundle exec kitchen login <INSTANCE>` after a failed
run, and sudo will be passwordless so you can debug.
