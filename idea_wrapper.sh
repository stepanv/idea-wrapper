#!/usr/local/bin/zsh -x
#
echo "START $@" >> /tmp/out.log
echo "line: $LINE" >> /tmp/out.log
PACKAGE='([a-zA-Z_$][a-zA-Z\d_$]*\.)*'
CLASSNAME='[a-zA-Z_$][a-zA-Z\d_$]*'
FILEANDLINE='[^/]*\.java:[0-9]*'

TIMEOUT=10

find_timeout() {
    file=${1?Missing filename}
    
    (
        /usr/local/bin/gtimeout $TIMEOUT find . -name "$file" || echo "!! Time out when looking for $file !!"
    ) | grep -v 'delombok' | head -n 1
}

find_path_timeout() {
    file=${1?Missing filename}
    
    (
        /usr/local/bin/gtimeout $TIMEOUT find . -path "$file" || echo "!! Time out when looking for $file !!"
    ) | grep -v '\.class$' | grep -v 'build/tmp/kapt3/stubs' | grep -v 'delombok' | head -n 1
}

arg="$@"

if [[ "$arg" =~ '.*:[0-9]+:[0-9]+$' ]]; then
    # the file ends with 'myfile:23:43'
    arg="${arg%:*}"
    echo "removed column: $arg" >> /tmp/out.log
fi

if [[ "$arg" =~ '^".*' ]] && [[ "$arg" =~ '.*"$' ]]; then
    arg="${arg:1}"
    arg="${arg: :-1}"
fi

if [[ "$arg" =~ '^@.*' ]]; then
    arg="${arg:1}"
fi

if [[ -d "$arg" ]] || [[ "$arg" =~ '.*\.html$' ]] || [[ "$arg" =~ '^http' ]]; then
    # open it
    open "$arg"
elif [[ "$arg" =~ '^[^/.]*\.java:[0-9][0-9]*$' || "$arg" =~ '^[^/.]*\.kt:[0-9][0-9]*$' ]]; then
    echo "HERE relative filename with line: $arg" >> /tmp/out.log
    # it's a relative java file
    found="$(find_timeout "${arg%:*}")"
    /usr/local/bin/idea --line ${arg#*:} "$found"
elif [[ "$arg" =~ '^[^/.]*\.java$' || "$arg" =~ '^[^/.]*\.kt$' ]]; then
    echo "HERE relative: $arg" >> /tmp/out.log
    # it's a relative java file
    found="$(find_timeout "$arg")"
    /usr/local/bin/idea "$found"
elif [[ "$arg" =~ "$PACKAGE$CLASSNAME\($FILEANDLINE\)" ]]; then
    # it's a relative java file
    file=$(echo "$arg" | sed -E "s/$PACKAGE$CLASSNAME\(([^)]*)\)/\\2/")
    echo "HERE extracted: $file" >> /tmp/out.log
    /usr/local/bin/idea --line ${file#*:} "$(find_timeout "${file%:*}")"
elif [[ "$arg" =~ "^$PACKAGE$CLASSNAME:[0-9][0-9]*$" ]]; then
    # it's a java class name with a line
    file=$(echo "$arg" | sed -E "s@\.@/@g")
    echo "HERE extracted relative with line: $file" >> /tmp/out.log

    /usr/local/bin/idea --line ${arg#*:} "$(find_path_timeout "*/${file%:*}.*" | grep -v '\.class$')"

elif [[ "$arg" =~ "^$PACKAGE$CLASSNAME$" ]]; then
    # it's a java class name
    file=$(echo "$arg" | sed -E "s@\.@/@g")
    echo "HERE extracted relative: $file" >> /tmp/out.log

    /usr/local/bin/idea "$(find_path_timeout "*/${file%:*}.*" | grep -v '\.class$')"

elif [[ "$arg" =~ '^@.*' ]]; then
    echo "HERE extracted file: ${arg:1}" >> /tmp/out.log
    /usr/local/bin/idea "${arg:1}"
else
    echo "HERE extracted file: ${arg}" >> /tmp/out.log
    /usr/local/bin/idea "$arg"
fi
