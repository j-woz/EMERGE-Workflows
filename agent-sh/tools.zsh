
# For use in ${(%)DATE_FMT}
DATE_FMT="%D{%Y-%m-%d} %D{%H:%M:%S}"

# For prefix of set -x
PS4='
+ '

msg()
{
  print ${(%)DATE_FMT} ${*}
}
msgv()
{
  local TEXT
  printf -v TEXT "${@}"
  print ${(%)DATE_FMT} ${TEXT}
}

# Expects 0 arguments:
alias args0='args - ${*}'
alias args='ARGS $0'

ARGS()
# File argument signature handling for shell scripts
# Must watch for user globals variables that collide with locals here
# Run with no arguments to get help for this function
# Usage:
# -e     : exit instead of return on errors
# -h     : provide application-level help
# -H MSG : an extra help message
# -v     : verbose output
# First argument: SELF
# Variable names (optionally with defaults X1:20 X2:30 ...)
# -
# Variable values (typically ${*})
{
  local _E="" _HELP="" _VERBOSE="" _L _MSG
  zparseopts -D -E e=_E h=_HELP H:=_MSG v=_VERBOSE

  _L=() # Required argument name list

  if (( ${#*} == 1 )) {
    _args_help
    if (( ${#_E} )) exit 1
    return 1
  }

  if (( ${#_MSG} )) _MSG=${_MSG[2]}

  # Setup SELF:basename
  local _SELF=${1:t}
  if (( ${#_VERBOSE} )) print "${_SELF}: ARGS: START"
  shift

  # Find variable names and dash
  while true
  do
    if (( ${#*} == 0 )) {
      print "${_SELF}: ARGS(): Could not find dash delimiter!"
      if (( ${#_E} )) exit 1
      return 1
    }
    if [[ ${1} == "-" ]] {
      shift
      break
    }
    # Found a variable name:
    _L+=$1
    shift
  done

  # Help?
  if (( ${#_HELP} )) {
    print "${_SELF}: usage: ${_L}"
    print $_MSG
    if (( ${#_E} )) exit 0
    return
  }

  local _GIVEN=${#*}
  if (( ${#_L} < ${_GIVEN} )) {
    print "${_SELF}: Requires ${#_L} arguments, given ${#*}"
    if (( ${#_L} > 0 )) print "${_SELF}: Arguments: ${_L}"
    if (( ${#_E} )) exit 1
    return 1
  }
  local _N=${#*} _KV _kv _K _V _i
  if (( ${#_VERBOSE} )) print "${_SELF}: ARGS: given N=${_N}"
  # This does colon splitting:
  typeset -T _KV _kv
  # Handle required arguments provided with values:
  for (( _i=1 ; _i<=_N ; _i++ ))
  do
    _KV=${_L[_i]}
    _K=${_kv[1]}
    eval "${_K}='${1}'"
    if (( ${#_VERBOSE} )) print "${_SELF}: ARGS: ${_K}='${1}'"
    shift
  done
  # Handle remaining required arguments: must have defaults!
  for (( ; _i<=${#_L} ; _i++ ))
  do
    _KV=${_L[_i]}
    _K=${_kv[1]}
    if (( ${#_kv} == 2 )) {
      _V=${_kv[2]}
      eval ${_K}=${_V}
      if (( ${#_VERBOSE} )) print "ARGS: ${_K}='${_V}' (default)"
    } else {
      print "${_SELF}: Requires ${#_L} arguments, given ${_GIVEN}"
      print "${_SELF}: Arguments: ${_L}"
      print "${_SELF}: Argument has no default: ${_K}"
      if (( ${#_E} )) exit 1
      return 1
    }
  done
  if (( ${#_VERBOSE} )) print "${_SELF}: ARGS: STOP"
}

_args_help()
{
  print "ARGS(): usage: "
  print "  -e : exit instead of return on errors"
  print "  -v : enable verbose output"
  print "       First argument: SELF"
  print "       Variable names (optionally with defaults X1:20 X2:30 ...)"
  print -- "  -"
  print '       Variable values (typically ${*})'
}

grab-rank()
# F: A real file to link to
# N: Integers to try: [0, N)
# REPLY: The integer assigned or -1 on error
{
  local F=$1
  local N=$2
  # i: index L: a hard link
  local i L
  for (( i=0 ; i < N ; i++ ))
  do
    L=$F-$i
    if ln $F $L
    then
      REPLY=$i
      return
    fi
  done
  return -1
}

rm0()
# File removal, ok with empty args and args that do not exist
# Safer than rm -f
#   -v   : verbose
#   -D   : individual treatment for directories (slower)
#   -Drv : if arg is directory, report directory name,
#                               not all contents
{
  local D R V
  zparseopts -D -E D=D r=R v=V
  local f
  declare -a FILES DIRS
  for f in ${*}
  do
    if [[ ! -e ${f} ]] continue
    if (( ${#D} )) && [[ -d ${f} ]] {
      DIRS+=${f}
    } else {
      FILES+=${f}
    }
  done

  local DIR
  for DIR in ${DIRS}
  do
    rm -r ${DIR}
    if (( ${#V} )) print "removed directory '${DIR}'"
  done

  if (( ${#FILES} == 0 )) return 0
  rm ${R} ${V} ${FILES}
}
