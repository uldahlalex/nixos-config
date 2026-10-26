import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';
import Meta from 'gi://Meta';

import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const ResizerIface = `
<node>
  <interface name="org.gnome.Shell.Extensions.Resizer">
    <method name="PickAndResize">
      <arg type="i" direction="in" name="width"/>
      <arg type="i" direction="in" name="height"/>
      <arg type="b" direction="out" name="success"/>
      <arg type="s" direction="out" name="message"/>
    </method>
  </interface>
</node>`;

// How long the pointer/keyboard grab is allowed to live before we force it
// to release. Without this, any bug that stops the click handler from
// firing would leave global.stage.grab() held forever, locking the whole
// session (observed once: cursor moved, nothing was clickable, required a
// reboot). This bounds the worst case to a few seconds.
const GRAB_TIMEOUT_SECONDS = 15;

const WindowPicker = GObject.registerClass({
    Signals: { 'picked': { param_types: [Meta.Window.$gtype] } },
}, class WindowPicker extends Clutter.Actor {
    _init() {
        super._init({ reactive: true });
        this.add_constraint(new Clutter.BindConstraint({
            source: global.stage,
            coordinate: Clutter.BindCoordinate.ALL,
        }));
        Main.uiGroup.add_child(this);

        this._finished = false;
        this._grab = null;
        this._timeoutId = null;

        this.connect('button-press-event', this._onButtonPress.bind(this));
        this.connect('key-press-event', this._onKeyPress.bind(this));
    }

    activate() {
        this._grab = Main.pushModal(this);
        if (!this._grab) {
            this._finish(null);
            return false;
        }
        // Arm the watchdog immediately, before anything else that could
        // throw (e.g. cursor-setting) and leave the grab un-releasable.
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, GRAB_TIMEOUT_SECONDS, () => {
                this._timeoutId = null;
                log('resizer: grab watchdog fired, forcing release');
                this._finish(null);
                return GLib.SOURCE_REMOVE;
            });
        // Cosmetic only: never let a failure here affect the grab/release path.
        try {
            this.set_cursor_type(Clutter.CursorType.CROSSHAIR);
        } catch (e) {
            logError(e, 'resizer: failed to set crosshair cursor (non-fatal)');
        }
        return true;
    }

    _onKeyPress(_actor, event) {
        if (event.get_key_symbol() === Clutter.KEY_Escape) {
            this._finish(null);
            return Clutter.EVENT_STOP;
        }
        return Clutter.EVENT_PROPAGATE;
    }

    _onButtonPress(_actor, event) {
        try {
            const [x, y] = event.get_coords();
            this._finish(this._findWindowAt(x, y));
        } catch (e) {
            logError(e, 'resizer: button press handling failed');
            this._finish(null);
        }
        return Clutter.EVENT_STOP;
    }

    // Walk actual window actors/geometry directly instead of relying on
    // Clutter picking through our own full-stage overlay, whose z-order
    // relative to window actors during an active stage grab isn't
    // something we want to bet the whole session's input on.
    _findWindowAt(x, y) {
        const actors = global.get_window_actors();
        for (let i = actors.length - 1; i >= 0; i--) {
            const win = actors[i].get_meta_window();
            if (!win || win.minimized)
                continue;
            const rect = win.get_frame_rect();
            if (x >= rect.x && x < rect.x + rect.width &&
                y >= rect.y && y < rect.y + rect.height)
                return win;
        }
        return null;
    }

    _finish(metaWindow) {
        if (this._finished)
            return;
        this._finished = true;

        if (this._timeoutId) {
            GLib.source_remove(this._timeoutId);
            this._timeoutId = null;
        }
        // Release the grab unconditionally before anything that could throw.
        if (this._grab) {
            Main.popModal(this._grab);
            this._grab = null;
        }
        try {
            this.set_cursor_type(Clutter.CursorType.DEFAULT);
        } catch (e) {
            logError(e, 'resizer: failed to reset cursor (non-fatal)');
        }
        this.emit('picked', metaWindow);
        this.destroy();
    }
});

export default class ResizerExtension extends Extension {
    enable() {
        this._dbusImpl = Gio.DBusExportedObject.wrapJSObject(ResizerIface, this);
        this._dbusImpl.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/Resizer');
        this._picker = null;
    }

    disable() {
        if (this._picker) {
            this._picker.destroy();
            this._picker = null;
        }
        this._dbusImpl.flush();
        this._dbusImpl.unexport();
        this._dbusImpl = null;
    }

    PickAndResizeAsync(params, invocation) {
        if (this._picker) {
            invocation.return_error_literal(
                Gio.DBusError, Gio.DBusError.FAILED,
                'A pick operation is already in progress');
            return;
        }

        const [width, height] = params;
        if (width <= 0 || height <= 0) {
            invocation.return_error_literal(
                Gio.DBusError, Gio.DBusError.INVALID_ARGS,
                'width and height must be positive integers');
            return;
        }

        let picker;
        try {
            picker = new WindowPicker();
        } catch (e) {
            logError(e, 'resizer: failed to create picker');
            invocation.return_error_literal(
                Gio.DBusError, Gio.DBusError.FAILED,
                `Failed to start picker: ${e.message}`);
            return;
        }
        this._picker = picker;

        picker.connect('picked', (_picker, metaWindow) => {
            this._picker = null;
            try {
                if (!metaWindow) {
                    invocation.return_value(new GLib.Variant('(bs)', [false, 'Cancelled or no window selected']));
                    return;
                }
                const rect = metaWindow.get_frame_rect();
                metaWindow.move_resize_frame(true, rect.x, rect.y, width, height);
                invocation.return_value(new GLib.Variant('(bs)', [true, metaWindow.get_title() ?? '']));
            } catch (e) {
                logError(e, 'resizer: resize failed');
                invocation.return_error_literal(
                    Gio.DBusError, Gio.DBusError.FAILED, `Resize failed: ${e.message}`);
            }
        });

        picker.activate();
    }
}
