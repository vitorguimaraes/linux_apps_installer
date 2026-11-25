#!/bin/bash
# Claude Code statusline: Powerline blocks in Dracula colors, one color per item.
#
#   Sonnet 5.5   Thinking: high   Ctx Used: 42%   5h: ▓▓▓░░│░░░░ 27%   Weekly: 61%
#
# Claude Code sends the session data as JSON on stdin; this prints one line.
# Needs jq, and a Nerd Font in the terminal (the arrows are the Powerline glyph U+E0B0).
#
# - The 5h bar: ▓ is how much of the 5-hour limit is used, │ marks how much of the
#   5-hour window has already passed. Fill behind the marker = below the pace of time.
# - An item that Claude Code did not send (no Pro/Max limits yet, a model without
#   thinking effort) is left out together with its arrow.
# Prints nothing, and never an error, when the input is not usable.

jq -r --argjson now "$(date +%s)" '
  # Dracula, as "r;g;b"
  def bg: {cyan: "139;233;253", purple: "189;147;249", orange: "255;184;108", pink: "255;121;198", yellow: "241;250;140"};
  def ink: "40;42;54";
  def clamp($v): [0, ([100, $v] | min)] | max;
  def esc: "\u001b[";

  # 10-cell bar: filled up to the used percent, the time marker over one cell
  def bar($used; $elapsed):
    (clamp($used) / 10 | round) as $filled
    | (if $elapsed == null then -1 else ([(clamp($elapsed) / 10 | floor), 9] | min) end) as $mark
    | [range(0; 10) | if . == $mark then "│" elif . < $filled then "▓" else "░" end] | join("");

  def seg($text; $color): {t: $text, bg: bg[$color]};

  [
    (.model.display_name // .model.id // empty | select(. != "") | seg(.; "cyan")),
    (.effort.level // empty | select(. != "") | seg("Thinking: \(.)"; "purple")),
    (.context_window.used_percentage // empty | seg("Ctx Used: \(round)%"; "orange")),
    (.rate_limits.five_hour // empty | select(.used_percentage != null)
      | (if .resets_at == null then null else ($now - (.resets_at - 18000)) / 18000 * 100 end) as $elapsed
      | seg("5h: \(bar(.used_percentage; $elapsed)) \(.used_percentage | round)%"; "pink")),
    (.rate_limits.seven_day.used_percentage // empty | seg("Weekly: \(round)%"; "yellow"))
  ] as $s
  | if ($s | length) == 0 then "" else
      ($s | to_entries | map(
        .key as $i | .value as $v
        | esc + "38;2;" + ink + ";48;2;" + $v.bg + "m " + $v.t + " "
        + (if $i + 1 < ($s | length)
           then esc + "38;2;" + $v.bg + ";48;2;" + $s[$i + 1].bg + "m"
           else esc + "0m" + esc + "38;2;" + $v.bg + "m" + esc + "0m" end)
      ) | join(""))
    end
' 2>/dev/null || true
