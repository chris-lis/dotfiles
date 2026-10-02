#!/usr/bin/env bash
# Claude Code subagent status line: one row per agent in the panel below the
# prompt. Reads the task list on stdin, prints a JSON line per task.
#
# Row: a left group (role · description · activity) and a right group
# (model effort · used/window · elapsed) right-aligned to the panel width the
# harness reports (narrower than the terminal). Squeezed, in this order, until
# the two fit: the window after the slash goes, the model shortens to its
# initial, then the DESCRIPTION goes when there is an activity (the activity is
# the fresher of the two; the description is what was typed at spawn time),
# and last whichever text is left is cut with an ellipsis. The elapsed time is
# always kept.
#
# The payload has no end time, so when an agent is first seen finished the
# current time is recorded in SL_SYNC_DIR/agent-<id>.end and the timer freezes
# there (accurate to one tick, fine at minute resolution).
#
# The role is the agent type from the meta file the harness writes beside the
# session transcript, `<transcript>/subagents/agent-<id>.meta.json`. That file
# is not part of the documented contract; a row without it starts at the
# description. (The documented `type` field is NOT usable for this: probing
# showed it is the task kind, "local_agent" for every subagent.)
#
# Probed 2026-09-19: the harness invokes this every ~5 s regardless of
# refreshInterval (1 was set), twice per tick ~200 ms apart. Elapsed time is
# therefore shown in whole minutes only; seconds would just step in fives.
# Diagnostics: touch ~/.cache/claude-statusline/subagent-debug to log each
# invocation's timestamp and input to ~/.cache/claude-statusline/subagent.log.

input=$(cat)
if [ -e "$HOME/.cache/claude-statusline/subagent-debug" ]; then
  printf '%s %s\n' "$(date '+%H:%M:%S.%N')" "$input" >> "$HOME/.cache/claude-statusline/subagent.log"
fi

# Locale: ${#str} must count characters, not bytes.
export LC_ALL=en_US.UTF-8

SEP=" · "
# The width the harness reports already excludes the panel's own prefix, so
# no margin is needed for the right group to sit flush with the main line.
SL_MARGIN=${SL_MARGIN:-0}
GL_WT=$'\xf3\xb0\x9c\x9b'   # U+F071B md-source_commit_local, as in the main line
SL_MIN_DESC=${SL_MIN_DESC:-8}

now=$(date +%s)
SL_SYNC_DIR="${SL_SYNC_DIR:-$HOME/.cache/claude-statusline}"
mkdir -p "$SL_SYNC_DIR" 2>/dev/null
find "$SL_SYNC_DIR" -name 'agent-*.end' -mmin +2880 -delete 2>/dev/null

IFS=$'\037' read -r transcript columns session_cwd <<EOF
$(printf '%s' "$input" | jq -j '[(.transcript_path // ""), ((.columns // 0) | tostring), (.cwd // "")] | join("")')
EOF
meta_dir="${transcript%.jsonl}/subagents"

# _fmt_tok <tokens> → 312, 312k, 1M, 1.2M
_fmt_tok() {
  local t=$1
  if (( t >= 1000000 )); then
    if (( t % 1000000 == 0 )); then printf '%dM' $(( t / 1000000 ))
    else printf '%d.%dM' $(( t / 1000000 )) $(( (t % 1000000) / 100000 )); fi
  elif (( t >= 1000 )); then printf '%dk' $(( t / 1000 ))
  else printf '%d' "$t"; fi
}

# _fmt_elapsed <seconds> → <1m, 4m, 1h12m (minute resolution, see header)
_fmt_elapsed() {
  local s=$1
  if   (( s >= 3600 )); then printf '%dh%02dm' $(( s / 3600 )) $(( (s % 3600) / 60 ))
  elif (( s >= 60 ));   then printf '%dm' $(( s / 60 ))
  else                       printf '<1m'; fi
}

# _model_short <model id> → "Opus5", "Fable5.1", "Haiku4.5"; the family
# capitalised, the numeric segments joined with a dot, a date segment dropped.
_model_short() {
  local id=${1%%[*} family version seg
  id=${id#claude-}
  family=${id%%-*}
  family="$(printf '%s' "${family:0:1}" | tr '[:lower:]' '[:upper:]')${family:1}"
  version=""
  IFS=- read -r -a segs <<EOF
${id#*-}
EOF
  for seg in "${segs[@]}"; do
    case "$seg" in
      [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
      *[!0-9]*|"") ;;
      *) version+="${version:+.}$seg" ;;
    esac
  done
  printf '%s%s' "$family" "$version"
}

# _join <parts...> → the non-empty parts joined with SEP
_join() {
  local out="" p
  for p in "$@"; do
    [ -z "$p" ] && continue
    out+="${out:+$SEP}$p"
  done
  printf '%s' "$out"
}

# _row <description> <activity> <window 1|0> <model initial 1|0>
# → sets ROW (right group padded flush right) and NEED (plain width of the
#   two groups plus the minimum gap, i.e. the columns the row needs)
_row() {
  local c="" m="" left right gap
  if [ "$3" = "1" ]; then c="$ctx_full"; else c="$ctx_used"; fi
  if [ "$4" = "1" ]; then m="$mdl_init"; else m="$mdl_short"; fi
  local d="$1" a="$2"
  # The worktree marker is a bare glyph in front of the first text item.
  if [ -n "$wt" ]; then
    if   [ -n "$d" ]; then d="$GL_WT $d"
    elif [ -n "$a" ]; then a="$GL_WT $a"
    else d="$GL_WT"; fi
  fi
  left=$(_join "$role" "$d" "$a")
  right=$(_join "${m:+$m${eff:+ $eff}}" "$c" "$elapsed")
  NEED=$(( ${#left} + ${#SEP} + ${#right} ))
  if (( columns > 0 )); then
    gap=$(( columns - SL_MARGIN - ${#left} - ${#right} ))
    (( gap < ${#SEP} )) && gap=${#SEP}
    ROW="${left}$(printf "%${gap}s" "")${right}"
  else
    ROW=$(_join "$left" "$right")
  fi
}

# _fits → the last ROW fits the panel width, or the width is unknown
_fits() { (( columns <= 0 || NEED <= columns - SL_MARGIN )); }

while IFS=$'\037' read -r id description label model effort window tokens start status task_cwd; do
  [ -z "$id" ] && continue

  # An agent working somewhere other than the session directory (an isolated
  # worktree, typically) is marked with the fork glyph.
  wt=""
  if [ -n "$task_cwd" ] && [ "$task_cwd" != "$session_cwd" ]; then wt=1; fi

  role=""
  [ -f "$meta_dir/agent-$id.meta.json" ] &&
    role=$(jq -r '.agentType // ""' "$meta_dir/agent-$id.meta.json" 2>/dev/null)

  # The activity starts equal to the description and only earns its place
  # once the agent reports something else.
  activity="$label"
  [ "$activity" = "$description" ] && activity=""

  mdl_short="" mdl_init=""
  if [ -n "$model" ]; then
    mdl_short=$(_model_short "$model"); mdl_init="${mdl_short:0:1}"
  fi
  case "$effort" in
    low)    eff="lo"  ;;
    medium) eff="md"  ;;
    high)   eff="hi"  ;;
    xhigh)  eff="xhi" ;;
    max)    eff="max" ;;
    *)      eff="$effort" ;;
  esac

  ctx_used=$(_fmt_tok "$tokens")
  ctx_full="$ctx_used"
  (( window > 0 )) && ctx_full+="/$(_fmt_tok "$window")"

  # Elapsed: live while running, frozen at the first tick the agent was seen
  # finished (see header).
  elapsed=""
  if (( start > 0 )); then
    end=$now
    if [ "$status" != "running" ]; then
      endf="$SL_SYNC_DIR/agent-${id//[^A-Za-z0-9_-]/}.end"
      if ! end=$(cat "$endf" 2>/dev/null) || [ -z "$end" ]; then
        end=$now; printf '%s\n' "$end" > "$endf" 2>/dev/null
      fi
    fi
    elapsed=$(_fmt_elapsed $(( end - start / 1000 )))
  fi

  # The text kept when only one of description/activity fits.
  text="$description"; [ -n "$activity" ] && text="$activity"
  found=""
  for variant in "D A 1 0" "D A 0 0" "D A 0 1" "T - 0 1"; do
    set -- $variant
    d=""; a=""
    [ "$1" = "D" ] && d="$description"
    [ "$1" = "T" ] && d="$text"
    [ "$2" = "A" ] && a="$activity"
    _row "$d" "$a" "$3" "$4"
    if _fits; then found=1; break; fi
  done
  if [ -z "$found" ]; then
    # Nothing fits whole: cut the text to the room left, or drop it.
    _row "" "" 0 1
    room=$(( columns - SL_MARGIN - NEED - ${#SEP} - 1 ))
    if (( room >= SL_MIN_DESC )); then
      _row "${text:0:$room}…" "" 0 1
    fi
  fi

  jq -cn --arg id "$id" --arg content "$ROW" '{id: $id, content: $content}'
done <<EOF
$(printf '%s' "$input" | jq -r '.tasks[]? | [
    .id, (.description // ""), (.label // ""), (.model // ""),
    ((.effort // "") | tostring), ((.contextWindowSize // 0) | tostring),
    ((.tokenCount // 0) | tostring), ((.startTime // 0) | tostring),
    (.status // ""), (.cwd // "")
  ] | join("")')
EOF
