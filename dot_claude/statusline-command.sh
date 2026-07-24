#!/usr/bin/env bash
# Claude Code status line
#
# Layout: left group (host · dir · git) and right group (model · effort ·
# context · 5h/7d usage), right-aligned using the COLUMNS the harness exports;
# falls back to a two-line layout when width is unknown or the groups collide.
#
# Git status comes from p10k's gitstatusd binary for exact z4h parity.
# Diagnostics: set STATUSLINE_DEBUG=1 to dump the input JSON + probe results.

input=$(cat)

# ── Locale: needed so ${#str} counts characters, not bytes ───────────────────
export LC_ALL=en_US.UTF-8
_lc_probe='ä'
if [ ${#_lc_probe} -ne 1 ]; then
  export LC_ALL=C.UTF-8
  if [ ${#_lc_probe} -ne 1 ]; then export LC_ALL=en_US.UTF-8; fi
fi

# ── Colors ───────────────────────────────────────────────────────────────────
RST=$'\033[0m'
BLD=$'\033[1m'
C_WHITE=$'\033[38;5;255m'
C_DIR=$'\033[38;5;75m'
C_MDL=$'\033[38;5;141m'
C_NEUTRAL=$'\033[38;5;252m'
C_SEP=$'\033[38;5;240m'
C_MUTE=$'\033[38;5;244m'
C_REMOTE=$'\033[38;5;208m'
# Shared warn ramp
C_YELLOW=$'\033[38;5;178m'
C_ORANGE=$'\033[38;5;208m'
C_RED=$'\033[38;5;196m'
# p10k VCS palette
G_CLEAN=$'\033[38;5;76m'
G_MOD=$'\033[38;5;178m'
G_UNTRACK=$'\033[38;5;39m'
G_CONFLICT=$'\033[38;5;196m'
G_META=$'\033[38;5;244m'

# Nerd Font glyphs, written as byte escapes so the source stays pure ASCII
# (BMP private-use characters are easily stripped by text tooling).
GL_APPLE=$'\xef\x85\xb9'   # U+F179 apple
GL_CLOUD=$'\xef\x83\x82'   # U+F0C2 cloud
GL_FOLDER=$'\xef\x81\xbb'  # U+F07B folder
GL_MODEL=$'\xf3\xb1\x99\xba'  # U+F167A robot

SEP_V="  ${C_SEP}│${RST}  "
SEP_P="  │  "

# ── Parse input (single jq call) ─────────────────────────────────────────────
# Fields are joined with 0x1f: a non-whitespace IFS keeps empty fields, which
# tab would silently collapse.
IFS=$'\037' read -r -a F <<EOF
$(printf '%s' "$input" | jq -j '
  [ (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.context_window.used_percentage // "" | tostring),
    (.context_window.total_input_tokens // "" | tostring),
    (.context_window.context_window_size // "" | tostring),
    (if .fast_mode then "1" else "" end),
    (.effort.level // ""),
    (.rate_limits.five_hour.used_percentage // "" | tostring),
    (.rate_limits.five_hour.resets_at // "" | tostring),
    (.rate_limits.seven_day.used_percentage // "" | tostring),
    (.rate_limits.seven_day.resets_at // "" | tostring),
    (.remote.session_id // "")
  ] | join("\u001f")')
EOF
cwd="${F[0]}"      model_name="${F[1]}"
ctx_pct="${F[2]}"  ctx_in="${F[3]}"    ctx_size="${F[4]}"
fast="${F[5]}"     effort="${F[6]}"
fh_pct="${F[7]}"   fh_reset="${F[8]}"
sd_pct="${F[9]}"   sd_reset="${F[10]}"
remote_id="${F[11]}"
[ -z "$cwd" ] && cwd="$(pwd)"

# ── Threshold ramp ───────────────────────────────────────────────────────────
# Percentages are compared in tenths so a threshold fires exactly on the
# boundary rather than a rounded-up approximation of it.
_pct10() {  # float percent → integer tenths (truncating)
  local f=$1 int frac
  int=${f%%.*}; frac=${f#*.}
  [ "$frac" = "$f" ] && frac=0
  frac="${frac}0"; frac=${frac:0:1}
  printf '%d' $(( int * 10 + frac ))
}
# _ramp <tenths> <t_yellow> <t_orange> <t_red> → sets RAMP to a color
_ramp() {
  local p=$1
  if   (( p >= $4 * 10 )); then RAMP="$C_RED"
  elif (( p >= $3 * 10 )); then RAMP="$C_ORANGE"
  elif (( p >= $2 * 10 )); then RAMP="$C_YELLOW"
  else                          RAMP="$C_NEUTRAL"
  fi
}

# ── Host indicator ───────────────────────────────────────────────────────────
host=$(hostname -s 2>/dev/null || hostname 2>/dev/null)
case "$host" in
  holy-mac*|*MacBook*|*macbook*)
    # Local mac: icon alone is enough
    host_glyph="$GL_APPLE"; host_label=""; host_col="$C_WHITE" ;;
  *)
    host_glyph="$GL_CLOUD"; host_label="$host"; host_col="$C_REMOTE" ;;
esac
if [ -n "$remote_id" ]; then
  host_label="☁${host_label:+ $host_label}"
fi

# ── Shorten path ─────────────────────────────────────────────────────────────
# NOTE: do not use "${cwd/#$HOME/~}" here — bash 5.x tilde-expands the
# replacement even when quoted, which turns "~" straight back into $HOME and
# silently defeats the substitution (bash 3.2 does not). Prefix-strip instead:
# a leading "~" inside double quotes is never tilde-expanded, in any version.
if [ "${cwd#$HOME}" != "$cwd" ]; then
  short_dir="~${cwd#$HOME}"
else
  short_dir="$cwd"
fi
IFS='/' read -ra parts <<< "$short_dir"
n=${#parts[@]}
if (( n > 3 )); then
  result="${parts[0]}"
  for (( i=1; i<n-2; i++ )); do result+="/${parts[$i]:0:1}"; done
  result+="/${parts[$((n-2))]}/${parts[$((n-1))]}"
  short_dir="$result"
fi

# ── Git status via gitstatusd (p10k parity) ──────────────────────────────────
br_kind="" br_text="" marks_v="" marks_p=""
GSD=""
for cand in \
  "$HOME/.cache/zsh4humans/v5/cache/gitstatus/gitstatusd-darwin-arm64" \
  "$HOME/.cache/zsh4humans/v5/cache/gitstatus/gitstatusd-linux-x86_64" \
  "$HOME/.cache/gitstatus/gitstatusd-darwin-arm64" \
  "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64"; do
  [ -x "$cand" ] && { GSD="$cand"; break; }
done
if [ -z "$GSD" ]; then
  GSD=$(ls "$HOME"/.cache/zsh4humans/v5/cache/gitstatus/gitstatusd-* \
             "$HOME"/.cache/gitstatus/gitstatusd-* 2>/dev/null | head -1)
fi

if [ -n "$GSD" ] && [ -x "$GSD" ]; then
  resp=$(printf 'q\x1f%s\x1f0\x1e' "$cwd" | \
    "$GSD" -s -1 -u -1 -c -1 -d -1 -m -1 --num-threads=8 2>/dev/null)
  if [ -n "$resp" ]; then
    IFS=$'\037' read -r -a G <<< "${resp%$'\036'}"
    if [ "${G[1]}" = "1" ]; then
      br="${G[4]}" up="${G[5]}" action="${G[8]}"
      n_staged="${G[10]}" n_unstaged="${G[11]}" n_conflict="${G[12]}"
      n_untrack="${G[13]}" ahead="${G[14]}" behind="${G[15]}"
      stashes="${G[16]}" tag="${G[17]}"
      p_ahead="${G[23]}" p_behind="${G[24]}" summary="${G[28]}"

      # The branch text is kept separate from the status marks so its length
      # can be chosen later, once the right-hand group's width is known.
      if [ -n "$br" ]; then
        br_kind="branch"; br_text="$br"
      elif [ -n "$tag" ]; then
        br_kind="tag";    br_text="$tag"
      else
        br_kind="commit"; br_text="${G[3]:0:8}"
      fi
      if [ -n "$up" ] && [ "$up" != "$br" ]; then
        marks_v+="${G_META}:${G_CLEAN}${up}"; marks_p+=":${up}"
      fi
      case "$summary" in
        wip*|WIP*|*[^[:alnum:]]wip|*[^[:alnum:]]WIP|*[^[:alnum:]]wip[^[:alnum:]]*|*[^[:alnum:]]WIP[^[:alnum:]]*)
          marks_v+=" ${G_MOD}wip"; marks_p+=" wip" ;;
      esac
      _m()  { marks_v+=" ${1}${2}"; marks_p+=" ${2}"; }
      _mn() { marks_v+="${1}${2}";  marks_p+="${2}"; }
      if [ "$behind" != "0" ] || [ "$ahead" != "0" ]; then
        [ "$behind" != "0" ] && _m "$G_CLEAN" "⇣${behind}"
        if [ "$ahead" != "0" ]; then
          if [ "$behind" != "0" ]; then _mn "$G_CLEAN" "⇡${ahead}"
          else _m "$G_CLEAN" "⇡${ahead}"; fi
        fi
      fi
      if [ "$p_behind" != "0" ] || [ "$p_ahead" != "0" ]; then
        [ "$p_behind" != "0" ] && _m "$G_CLEAN" "⇠${p_behind}"
        if [ "$p_ahead" != "0" ]; then
          if [ "$p_behind" != "0" ]; then _mn "$G_CLEAN" "⇢${p_ahead}"
          else _m "$G_CLEAN" "⇢${p_ahead}"; fi
        fi
      fi
      [ "$stashes"    != "0" ] && _m "$G_CLEAN"    "*${stashes}"
      [ -n "$action" ]         && _m "$G_CONFLICT" "$action"
      [ "$n_conflict" != "0" ] && _m "$G_CONFLICT" "~${n_conflict}"
      [ "$n_staged"   != "0" ] && _m "$G_MOD"      "+${n_staged}"
      [ "$n_unstaged" != "0" ] && [ "$n_unstaged" != "-1" ] && _m "$G_MOD" "!${n_unstaged}"
      [ "$n_untrack"  != "0" ] && _m "$G_UNTRACK"  "?${n_untrack}"
      [ "$n_unstaged" = "-1" ] && _m "$G_MOD"      "─"
      marks_v+="$RST"
    fi
  fi
fi
# Fallback: plain branch name if gitstatusd is unavailable
if [ -z "$br_text" ]; then
  if b=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
    br_kind="branch"; br_text="$b"
  elif b=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
    br_kind="commit"; br_text="$b"
  fi
fi

# ── Branch-name variants, longest first ──────────────────────────────────────
# Only the branch text shrinks, and it shrinks from the FRONT: leading path
# components collapse to initials before the final, informative segment is
# touched. Tags and bare commits are never shortened.
BR_VARIANTS=()
if [ -n "$br_text" ]; then
  BR_VARIANTS+=("$br_text")
  if [ "$br_kind" = "branch" ] && [[ "$br_text" == */* ]]; then
    last="${br_text##*/}"; lead="${br_text%/*}"
    IFS='/' read -ra lsegs <<< "$lead"
    ini=""
    for seg in "${lsegs[@]}"; do ini+="${seg:0:1}/"; done
    BR_VARIANTS+=("${ini}${last}")
    BR_VARIANTS+=("$last")
  fi
fi

# _git_seg <branch text> → sets GS_V / GS_P
_git_seg() {
  case "$br_kind" in
    tag)    GS_V="${G_META}#${G_CLEAN}${1}"; GS_P="#${1}" ;;
    commit) GS_V="${G_META}@${G_CLEAN}${1}"; GS_P="@${1}" ;;
    *)      GS_V="${G_CLEAN}${1}";          GS_P="${1}"   ;;
  esac
  GS_V+="${marks_v}"; GS_P+="${marks_p}"
}

# ── Model + effort + fast mode ───────────────────────────────────────────────
# "Opus 5 (1M context)" → "Opus5"; the window size is shown by the context
# segment, so it is not repeated here.
if [[ "$model_name" =~ ^([A-Za-z]+)[[:space:]]+([0-9]+(\.[0-9]+)?) ]]; then
  mdl_short="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
else
  mdl_short="$model_name"
fi

eff=""
case "$effort" in
  low)    eff="lo"  ;;
  medium) eff="md"  ;;
  high)   eff="hi"  ;;
  xhigh)  eff="xhi" ;;
  max)    eff="max" ;;
esac
if [ -n "$fast" ]; then eff="${eff:+$eff }⚡"; fi

mdl_v="" mdl_p=""
if [ -n "$mdl_short" ]; then
  mdl_v="${C_MDL}${GL_MODEL} ${mdl_short}${RST}"
  mdl_p="${GL_MODEL} ${mdl_short}"
  if [ -n "$eff" ]; then
    mdl_v+=" ${C_MUTE}${eff}${RST}"; mdl_p+=" ${eff}"
  fi
fi

# ── Context: absolute tokens / window, colored by % of window ────────────────
# Ramp: <20% neutral, >=20% yellow (the 200k pricing boundary on a 1M window),
# >=50% orange, >=80% red.
_fmt_tok() {
  local t=$1
  if (( t >= 1000000 )); then
    if (( t % 1000000 == 0 )); then printf '%dM' $(( t / 1000000 ))
    else printf '%d.%dM' $(( t / 1000000 )) $(( (t % 1000000) / 100000 )); fi
  elif (( t >= 1000 )); then printf '%dk' $(( t / 1000 ))
  else printf '%d' "$t"; fi
}

ctx_v="" ctx_p=""
if [ -n "$ctx_pct" ]; then
  cpct=$(printf "%.0f" "$ctx_pct")
  _ramp "$(_pct10 "$ctx_pct")" 20 50 80
  if [ -n "$ctx_in" ] && [ -n "$ctx_size" ] && [ "$ctx_size" != "0" ]; then
    ctx_used="$(_fmt_tok "$ctx_in")"; ctx_tot="$(_fmt_tok "$ctx_size")"
    # Only the tokens actually used carry the ramp colour; the window size is
    # a fixed reference value, so it stays muted.
    ctx_v="${RAMP}${ctx_used}${C_MUTE}/${ctx_tot}${RST}"
    ctx_p="${ctx_used}/${ctx_tot}"
  else
    ctx_p="${cpct}%"
    ctx_v="${RAMP}${ctx_p}${RST}"
  fi
fi

# ── Rate-limit windows ───────────────────────────────────────────────────────
# resets_at may be epoch seconds or an ISO-8601 timestamp.
read now tzoff_raw <<EOF
$(date '+%s %z')
EOF
# "+0200" / "-0600" → seconds east of UTC, needed to place local day boundaries
tz_h="${tzoff_raw:1:2}"; tz_m="${tzoff_raw:3:2}"
tzoff=$(( 10#$tz_h * 3600 + 10#$tz_m * 60 ))
[ "${tzoff_raw:0:1}" = "-" ] && tzoff=$(( -tzoff ))

# ── Work-week model ──────────────────────────────────────────────────────────
# Pace is measured against AVAILABLE time, not calendar time. On a team or
# enterprise account weekends do not count (and any 7-day span contains exactly
# five weekdays' worth of seconds, so the denominator needs no alignment
# special-casing); on a personal account every day counts. SL_WORK_DAYS
# overrides the detection: digits are weekdays, 0=Sunday .. 6=Saturday.
if [ -z "${SL_WORK_DAYS:-}" ]; then
  case "$(jq -r '.oauthAccount.organizationType // ""' "$HOME/.claude.json" 2>/dev/null)" in
    *team*|*enterprise*) SL_WORK_DAYS="12345"   ;;
    *)                   SL_WORK_DAYS="0123456" ;;
  esac
fi

# _work_secs <start epoch> <end epoch> → seconds falling on SL_WORK_DAYS
_work_secs() {
  local a=$(( $1 + tzoff )) b=$(( $2 + tzoff )) tot=0 d d0 d1 dow ds de
  if (( b <= a )); then printf '0'; return; fi
  d0=$(( a / 86400 )); d1=$(( b / 86400 ))
  for (( d=d0; d<=d1; d++ )); do
    dow=$(( (d + 4) % 7 ))
    case "$SL_WORK_DAYS" in *"$dow"*) ;; *) continue ;; esac
    ds=$(( d * 86400 )); de=$(( ds + 86400 ))
    (( ds < a )) && ds=$a
    (( de > b )) && de=$b
    (( de > ds )) && tot=$(( tot + de - ds ))
  done
  printf '%d' "$tot"
}
_reset_epoch() {
  case "$1" in
    ''|*[!0-9]*)
      date -j -f "%Y-%m-%dT%H:%M:%S" "${1%%.*}" +%s 2>/dev/null ||
      date -d "$1" +%s 2>/dev/null ;;
    *) printf '%s' "$1" ;;
  esac
}
_countdown() {
  local secs=$1
  (( secs < 0 )) && secs=0
  local d=$(( secs / 86400 )) h=$(( (secs % 86400) / 3600 )) m=$(( (secs % 3600) / 60 ))
  if   (( d > 0 )); then printf '%dd%dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh%02dm' "$h" "$m"
  else                   printf '%dm' "$m"
  fi
}
# Usage is coloured by BURN RATE, not by absolute percentage. The pace ratio is
#
#     pace = used% / elapsed%          (elapsed as a % of the window)
#
# so pace 1.0 means the budget runs out exactly at the reset moment, and
# pace x 100 is the projected usage at reset. The payload gives resets_at but
# no window start, so elapsed is derived as window_length - time_to_reset;
# that assumes the window is exactly 5h / 7d long and anchored to its reset.
#
# Note used% <= pace * 100 always (since elapsed% <= 100), so a high absolute
# usage necessarily implies a high pace — no separate absolute floor is needed.
WIN_5H=18000     # 5 hours
WIN_7D=604800    # 7 days
# $5=1 weights elapsed time by SL_WORK_DAYS; the 5h window always uses calendar
# time, since a 5h window falling entirely on a weekend would have a zero
# denominator and weekends are meaningless inside a 5-hour span anyway.
_usage_seg() {  # $1=label $2=pct $3=resets_at $4=window secs $5=weight → U_V/U_P
  U_V="" U_P=""
  [ -z "$2" ] && return
  local p p10 ep cd start el tot win pace100
  p=$(printf "%.0f" "$2")
  p10=$(_pct10 "$2")
  win=$4
  ep=$(_reset_epoch "$3")
  RAMP="$C_NEUTRAL"
  if [ -n "$ep" ]; then
    start=$(( ep - win ))
    if [ "$5" = "1" ]; then
      el=$(_work_secs "$start" "$now"); tot=$(_work_secs "$start" "$ep")
    else
      el=$(( now - start )); tot=$win
    fi
    (( el > tot )) && el=$tot
    # Below 5% of the available time elapsed, or under 3% used, the projection
    # is dominated by noise (1% in the first minute projects to 300%).
    if (( el > 0 && tot > 0 && el * 100 / tot >= 5 && p10 >= 30 )); then
      pace100=$(( p10 * tot / (10 * el) ))
      if   (( pace100 >= 125 )); then RAMP="$C_RED"
      elif (( pace100 >= 100 )); then RAMP="$C_ORANGE"
      elif (( pace100 >=  90 )); then RAMP="$C_YELLOW"
      fi
    fi
  fi
  U_V="${C_MUTE}${1}${RST} ${RAMP}${p}%${RST}"
  U_P="${1} ${p}%"
  if [ -n "$ep" ]; then
    cd=$(_countdown $(( ep - now )))
    U_V+=" ${C_MUTE}↻${cd}${RST}"; U_P+=" ↻${cd}"
  fi
}

_usage_seg "5h" "$fh_pct" "$fh_reset" "$WIN_5H" 0; fh_v="$U_V" fh_p="$U_P"
_usage_seg "7d" "$sd_pct" "$sd_reset" "$WIN_7D" 1; sd_v="$U_V" sd_p="$U_P"

# ── Assemble groups ──────────────────────────────────────────────────────────
# _compose_left <branch text> → sets L_V (with colour) / L_P (plain, for width)
_compose_left() {
  L_V="${host_col}${host_glyph}${host_label:+ $host_label}${RST}"
  L_P="${host_glyph}${host_label:+ $host_label}"
  L_V+="${SEP_V}${C_DIR}${BLD}${GL_FOLDER} ${short_dir}${RST}"
  L_P+="${SEP_P}${GL_FOLDER} ${short_dir}"
  if [ -n "$br_text" ]; then
    _git_seg "$1"
    L_V+="${SEP_V}${GS_V}"; L_P+="${SEP_P}${GS_P}"
  fi
}
_compose_left "$br_text"

R_V="" R_P=""
_radd() { [ -z "$2" ] && return
  if [ -n "$R_P" ]; then R_V+="${SEP_V}"; R_P+="${SEP_P}"; fi
  R_V+="$1"; R_P+="$2"; }
_radd "$mdl_v" "$mdl_p"
_radd "$ctx_v" "$ctx_p"
_radd "$fh_v"  "$fh_p"
_radd "$sd_v"  "$sd_p"

# ── Terminal width ───────────────────────────────────────────────────────────
# Claude Code exports COLUMNS with the real terminal width; /dev/tty is NOT
# reachable from the status-line subprocess, so the stty/tput probes are only
# a safety net for other hosts.
cols="${COLUMNS:-}"
if [ -z "$cols" ]; then
  if size=$(stty size 2>/dev/null < /dev/tty); then cols="${size#* }"; fi
fi
if [ -z "$cols" ]; then
  cols=$(tput cols 2>/dev/null < /dev/tty)
fi

if [ "${STATUSLINE_DEBUG:-}" = "1" ]; then
  {
    printf '=== %s ===\ncols=%s COLUMNS=%s TERM=%s LC_ALL=%s left=%s right=%s\n' \
      "$(date -u +%FT%TZ)" "$cols" "${COLUMNS:-UNSET}" "${TERM:-UNSET}" \
      "$LC_ALL" "${#L_P}" "${#R_P}"
    printf 'INPUT: %s\n' "$input"
  } >> "${STATUSLINE_DEBUG_FILE:-/tmp/claude-statusline-debug.log}"
fi

# ── Print ────────────────────────────────────────────────────────────────────
# Width is measured in characters, but Nerd Font glyphs may render as 2 cells
# in some terminals. SL_MARGIN keeps a few columns spare so the line can never
# wrap; raise it if you ever see wrapping, lower it for a tighter flush-right.
SL_MARGIN=${SL_MARGIN:-4}
if [ -n "$R_P" ] && [ -n "$cols" ] && [ "$cols" -gt 0 ] 2>/dev/null; then
  # Try each branch variant longest-first and take the first that fits on one
  # line, so the full branch name is shown whenever there is room for it.
  for cand in "${BR_VARIANTS[@]:-}"; do
    _compose_left "$cand"
    gap=$(( cols - SL_MARGIN - ${#L_P} - ${#R_P} ))
    if (( gap >= 3 )); then
      printf '%s%s%s\n' "$L_V" "$(printf "%${gap}s" "")" "$R_V"
      exit 0
    fi
  done
  # Nothing fit whole: middle-truncate the shortest variant to the space left.
  if [ ${#BR_VARIANTS[@]} -gt 0 ]; then
    shortest="${BR_VARIANTS[$(( ${#BR_VARIANTS[@]} - 1 ))]}"
    _compose_left ""
    # Below SL_MIN_BRANCH a truncated name carries less information than
    # simply moving to two lines and showing it in full, so prefer that.
    room=$(( cols - SL_MARGIN - 3 - ${#L_P} - ${#R_P} ))
    if (( room >= ${SL_MIN_BRANCH:-16} )); then
      keep=$(( room - 1 ))
      head=$(( keep / 2 )); tail=$(( keep - head ))
      _compose_left "${shortest:0:$head}…${shortest: -$tail}"
      gap=$(( cols - SL_MARGIN - ${#L_P} - ${#R_P} ))
      if (( gap >= 3 )); then
        printf '%s%s%s\n' "$L_V" "$(printf "%${gap}s" "")" "$R_V"
        exit 0
      fi
    fi
  fi
fi
# Fallback / narrow terminal: two lines, with the full branch name
_compose_left "$br_text"
if [ -n "$R_P" ]; then
  printf '%s\n%s\n' "$L_V" "$R_V"
else
  printf '%s\n' "$L_V"
fi
