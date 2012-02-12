#!/bin/sh

# Actual directories and names for the installed files:

luadir='/usr/local/share/moonlime'  # Lua modules
tmpldir='/usr/local/share/moonlime' # The default code template
bindir='/usr/local/bin'             # The top-level executable
binname='moonlime'                  # The name for the executable
interpname='/usr/bin/lua5.1'        # The actual filename of the Lua 5.1
                                    #   standalone interpreter

cd "$(dirname "$0")"

. ./inst-action.sh
