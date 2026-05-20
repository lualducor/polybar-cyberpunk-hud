#!/usr/bin/env python3

import json
import re
import subprocess
import sys

WINDOW_TYPES = {"con", "floating_con"}


def run_i3(*args):
    result = subprocess.run(
        ["i3-msg", *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(result.stderr.strip() or "i3-msg command failed")
    return result.stdout


def load_json(query):
    try:
        return json.loads(run_i3("-t", query))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid i3-msg JSON for {query}: {exc}") from exc


def workspace_number(name):
    match = re.match(r"\s*(\d+)", name or "")
    return int(match.group(1)) if match else None


def choose_new_workspace(workspaces):
    used = {workspace_number(ws.get("name")) for ws in workspaces}
    used.discard(None)
    candidate = 1
    while candidate in used:
        candidate += 1
    return candidate


def quote_i3(value):
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def walk(node):
    yield node
    for child in node.get("nodes", []):
        yield from walk(child)
    for child in node.get("floating_nodes", []):
        yield from walk(child)


def focused_node(node):
    if not node.get("focused"):
        return None
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        if child.get("focused"):
            return focused_node(child)
    return node


def find_workspace(tree, workspace_name):
    for node in walk(tree):
        if node.get("type") == "workspace" and node.get("name") == workspace_name:
            return node
    return None


def find_node_by_id(tree, node_id):
    for node in walk(tree):
        if node.get("id") == node_id:
            return node
    return None


def child_nodes(node):
    return node.get("nodes", []) + node.get("floating_nodes", [])


def is_window_node(node):
    return (
        (node or {}).get("type") in WINDOW_TYPES
        and (
            (node or {}).get("window") is not None
            or (node or {}).get("window_properties")
        )
    )


def is_scratchpad_node(node):
    return (node or {}).get("scratchpad_state") not in {None, "none"}


def scratchpad_has_windows(tree):
    scratchpad = find_workspace(tree, "__i3_scratch")
    if scratchpad is None:
        return False
    return bool(scratchpad.get("nodes") or scratchpad.get("floating_nodes"))


def focused_workspace(tree, workspaces):
    current = next((ws for ws in workspaces if ws.get("focused")), None)
    if current is None:
        return None
    return find_workspace(tree, current.get("name"))


def resolve_window_node(tree, node):
    if node is None:
        return None
    if is_window_node(node):
        return node

    children = child_nodes(node)
    child_by_id = {child.get("id"): child for child in children}

    for child_id in node.get("focus", []):
        child = child_by_id.get(child_id) or find_node_by_id(tree, child_id)
        match = resolve_window_node(tree, child)
        if match is not None:
            return match

    for child in children:
        match = resolve_window_node(tree, child)
        if match is not None:
            return match

    return None


def target_window_node(tree, workspaces):
    node = focused_node(tree)
    if is_window_node(node):
        return node
    return resolve_window_node(tree, focused_workspace(tree, workspaces))


def move_target(target):
    if isinstance(target, int):
        return f"workspace number {target}"
    return f"workspace {quote_i3(target)}"


def focus_workspace(target):
    run_i3(move_target(target))


def create_workspace():
    target = choose_new_workspace(load_json("get_workspaces"))
    focus_workspace(target)


def delete_workspace():
    workspaces = load_json("get_workspaces")
    current = next((ws for ws in workspaces if ws.get("focused")), None)
    if current is None:
        raise SystemExit("No focused workspace")

    current_name = current.get("name")
    current_number = workspace_number(current_name)

    numeric_targets = sorted(
        number
        for ws in workspaces
        if ws.get("name") != current_name
        for number in [workspace_number(ws.get("name"))]
        if number is not None
    )

    if current_number is not None:
        lower = [number for number in numeric_targets if number < current_number]
        higher = [number for number in numeric_targets if number > current_number]
        if lower:
            target = lower[-1]
        elif higher:
            target = higher[0]
        else:
            target = current_number + 1
    else:
        other_names = [ws.get("name") for ws in workspaces if ws.get("name") != current_name]
        target = other_names[0] if other_names else choose_new_workspace(workspaces)

    tree = load_json("get_tree")
    workspace_node = find_workspace(tree, current_name)
    if workspace_node is not None:
        top_level_nodes = [
            node["id"]
            for node in workspace_node.get("nodes", [])
            if node.get("type") != "dockarea"
        ]
        floating_nodes = [node["id"] for node in workspace_node.get("floating_nodes", [])]
        for con_id in top_level_nodes + floating_nodes:
            run_i3(f"[con_id={con_id}] move container to {move_target(target)}")

    focus_workspace(target)


def minimize_window():
    tree = load_json("get_tree")
    workspaces = load_json("get_workspaces")
    node = target_window_node(tree, workspaces)
    if node is None:
        return
    if is_scratchpad_node(node):
        run_i3("scratchpad show")
        return
    run_i3(f"[con_id={node['id']}] move scratchpad")


def restore_window():
    tree = load_json("get_tree")
    workspaces = load_json("get_workspaces")
    node = target_window_node(tree, workspaces)
    if is_scratchpad_node(node) or scratchpad_has_windows(tree):
        run_i3("scratchpad show")


def fullscreen_window():
    tree = load_json("get_tree")
    workspaces = load_json("get_workspaces")
    node = target_window_node(tree, workspaces)
    if node is None:
        return
    run_i3(f"[con_id={node['id']}] fullscreen toggle")


def toggle_window():
    tree = load_json("get_tree")
    workspaces = load_json("get_workspaces")
    node = target_window_node(tree, workspaces)
    if node is None and not scratchpad_has_windows(tree):
        return
    if is_scratchpad_node(node) or scratchpad_has_windows(tree):
        run_i3("scratchpad show")
        return
    run_i3(f"[con_id={node['id']}] move scratchpad")


def main():
    if len(sys.argv) != 2:
        raise SystemExit(
            "Usage: i3_workspace.py <create|delete|minimize|restore|toggle|fullscreen>"
        )

    command = sys.argv[1]
    if command == "create":
        create_workspace()
    elif command == "delete":
        delete_workspace()
    elif command == "minimize":
        minimize_window()
    elif command == "restore":
        restore_window()
    elif command == "toggle":
        toggle_window()
    elif command == "fullscreen":
        fullscreen_window()
    else:
        raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
