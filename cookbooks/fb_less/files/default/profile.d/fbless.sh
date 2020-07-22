# shellcheck shell=sh

# Set some useful LESS options.  If you prefer your own, set it in
# your shell startup script and it will be honored.
if [ -z "${LESS+set}" ]; then
    export LESS='-n -i'
fi
if [ -z "${LESSOPEN+set}" ]; then
	export LESSOPEN='||/usr/local/bin/lesspipe.sh %s'
fi
