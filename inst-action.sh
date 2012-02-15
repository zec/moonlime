# Called by install.sh (or some other file specifying the same variables
# as install.sh); expected to be run from the directory it's located in.

TMPLUA="$(mktemp --tmpdir=. 'tmp.XXXXXXXXXX')"
sed -e '1c#!'"${interpname}" \
    -e '/^package\.path/cpackage.path = "'"${luadir}"'/?.lua"' \
    <moonlime >"${TMPLUA}"

mkdir -p "${luadir}" "${tmpldir}" "${bindir}"

PKGS="limeparse.lua limeutil.lua"
install -m 444 ${PKGS} "${luadir}"
install -m 755 ${TMPLUA} "${bindir}/${binname}"
