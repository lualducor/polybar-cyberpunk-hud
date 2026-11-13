import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const BUS_NAME = 'com.openmirai.CyberpunkHud';
const OBJECT_PATH = '/com/openmirai/CyberpunkHud';
const INTERFACE_XML = `
<node>
  <interface name="com.openmirai.CyberpunkHud">
    <method name="GetStatus">
      <arg type="s" direction="out" name="status"/>
    </method>
    <method name="Action">
      <arg type="s" direction="in" name="action"/>
      <arg type="b" direction="out" name="success"/>
    </method>
  </interface>
</node>`;

class HudBridge {
    constructor() {
        this._exported = Gio.DBusExportedObject.wrapJSObject(INTERFACE_XML, this);
        this._exported.export(Gio.DBus.session, OBJECT_PATH);
        this._ownerId = Gio.bus_own_name_on_connection(
            Gio.DBus.session,
            BUS_NAME,
            Gio.BusNameOwnerFlags.NONE,
            null,
            null
        );
    }

    GetStatus() {
        const manager = global.workspace_manager;
        const window = global.display.focus_window;
        const status = {
            workspace: manager.get_active_workspace_index(),
            workspaces: manager.n_workspaces,
            title: window?.get_title() ?? '',
            maximized: window
                ? window.get_maximized() === Meta.MaximizeFlags.BOTH
                : false,
            fullscreen: window?.is_fullscreen() ?? false,
        };
        return JSON.stringify(status);
    }

    Action(action) {
        try {
            const manager = global.workspace_manager;
            const window = global.display.focus_window;
            const timestamp = global.get_current_time();

            if (action.startsWith('workspace:')) {
                const index = Number.parseInt(action.split(':')[1], 10);
                const workspace = manager.get_workspace_by_index(index);
                if (!workspace)
                    return false;
                workspace.activate(timestamp);
                return true;
            }

            if (action === 'workspace-next' || action === 'workspace-prev') {
                const direction = action.endsWith('next')
                    ? Meta.MotionDirection.RIGHT
                    : Meta.MotionDirection.LEFT;
                manager.get_active_workspace().get_neighbor(direction).activate(timestamp);
                return true;
            }

            if (action === 'workspace-new') {
                manager.append_new_workspace(false, timestamp).activate(timestamp);
                return true;
            }

            if (action === 'workspace-delete') {
                if (manager.n_workspaces <= 1)
                    return false;
                manager.remove_workspace(manager.get_active_workspace(), timestamp);
                return true;
            }

            if (action === 'overview') {
                Main.overview.toggle();
                return true;
            }

            if (!window)
                return false;

            if (action === 'minimize')
                window.minimize();
            else if (action === 'maximize') {
                if (window.get_maximized() === Meta.MaximizeFlags.BOTH)
                    window.unmaximize(Meta.MaximizeFlags.BOTH);
                else
                    window.maximize(Meta.MaximizeFlags.BOTH);
            } else if (action === 'fullscreen') {
                if (window.is_fullscreen())
                    window.unmake_fullscreen();
                else
                    window.make_fullscreen();
            } else if (action === 'close')
                window.delete(timestamp);
            else if (action === 'center') {
                const rect = window.get_frame_rect();
                const monitor = global.display.get_monitor_geometry(window.get_monitor());
                window.move_frame(true,
                    monitor.x + Math.floor((monitor.width - rect.width) / 2),
                    monitor.y + Math.floor((monitor.height - rect.height) / 2));
            } else if (['left', 'right', 'up', 'down'].includes(action)) {
                const rect = window.get_frame_rect();
                const dx = action === 'left' ? -30 : action === 'right' ? 30 : 0;
                const dy = action === 'up' ? -30 : action === 'down' ? 30 : 0;
                window.move_frame(true, rect.x + dx, rect.y + dy);
            } else {
                return false;
            }
            return true;
        } catch (error) {
            console.error(`Cyberpunk HUD action failed (${action}): ${error}`);
            return false;
        }
    }

    destroy() {
        if (this._ownerId)
            Gio.bus_unown_name(this._ownerId);
        this._exported?.unexport();
    }
}

export default class CyberpunkHudExtension extends Extension {
    enable() {
        this._bridge = new HudBridge();
    }

    disable() {
        this._bridge?.destroy();
        this._bridge = null;
    }
}
