if [[ $# -ne 2 ]]; then
  echo "Usage: resizer WIDTH HEIGHT" >&2
  echo "  Crosshair cursor appears; click a window to resize it to WIDTH x HEIGHT." >&2
  exit 1
fi

width="$1"
height="$2"

if ! [[ "$width" =~ ^[0-9]+$ ]] || ! [[ "$height" =~ ^[0-9]+$ ]]; then
  echo "Error: WIDTH and HEIGHT must be positive integers" >&2
  exit 1
fi

if ! output=$(gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell/Extensions/Resizer \
  --method org.gnome.Shell.Extensions.Resizer.PickAndResize \
  "$width" "$height" 2>&1); then
  echo "Error calling resizer extension: $output" >&2
  echo "(Is the 'resizer' GNOME Shell extension enabled? Try: gnome-extensions enable resizer@local.dev)" >&2
  exit 1
fi

if [[ "$output" == *"(true,"* ]]; then
  echo "Resized window to ${width}x${height}."
else
  echo "No window selected (cancelled with Esc, or clicked outside a window)."
fi
