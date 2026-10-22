import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs
import qs.components

// The Files app: a Material 3 file explorer (qs ipc call files toggle, or "Files" in the launcher).
// Browsing uses Qt's FolderListModel (updates live); file operations run cp / mv / gio in the background.
LazyLoader {
    active: Globals.filesOpen

    FloatingWindow {
        id: win

        title: "Files"
        implicitWidth: 1120
        implicitHeight: 740
        color: Theme.bg0
        onVisibleChanged: if (!visible) Globals.filesOpen = false

        readonly property string home: Quickshell.env("HOME")
        readonly property string trashDir: home + "/.local/share/Trash/files"
        readonly property bool inTrash: path === trashDir || path.startsWith(trashDir + "/")

        // Navigation
        property string path: ""
        property var history: []
        property int historyIndex: -1

        // Selection: path → true
        property var selected: ({})
        readonly property int selectedCount: Object.keys(selected).length
        property int anchorIndex: -1

        // Clipboard (also exported to the system clipboard as file URIs)
        property var clipPaths: []
        property bool clipCut: false

        // Search (recursive, in the current folder)
        property string query: ""
        readonly property bool searching: query !== ""
        readonly property var model: searching ? searchModel : folderModel
        readonly property bool listMode: Config.files.view === "list" || searching

        // ---------- helpers ----------
        function normalize(p) {
            p = p.trim();
            if (p === "~" || p.startsWith("~/")) p = home + p.slice(1);
            if (p.startsWith("file://")) p = decodeURIComponent(p.slice(7));
            p = p.replace(/\/+/g, "/");
            if (p.length > 1 && p.endsWith("/")) p = p.slice(0, -1);
            return p || "/";
        }
        function parentOf(p) { return p.substring(0, p.lastIndexOf("/")) || "/"; }
        function baseName(p) { return p === "/" ? "/" : p.substring(p.lastIndexOf("/") + 1); }
        function prettyPath(p) {
            if (p === home) return "~";
            return p.startsWith(home + "/") ? "~" + p.slice(home.length) : p;
        }
        function join(dir, name) { return (dir === "/" ? "" : dir) + "/" + name; }
        function pathAt(i) { return searching ? searchModel.get(i).filePath : folderModel.get(i, "filePath"); }
        function isDirAt(i) { return searching ? searchModel.get(i).fileIsDir : folderModel.get(i, "fileIsDir"); }
        function sizeAt(i) { return searching ? searchModel.get(i).fileSize : folderModel.get(i, "fileSize"); }
        function selectedPaths() { return Object.keys(selected); }
        function quote(s) { return "'" + s.replace(/'/g, "'\\''") + "'"; }

        // ---------- navigation ----------
        property int navDir: 1
        function go(p, fromHistory) {
            p = normalize(p);
            if (p === path && !searching) return;
            if (!fromHistory) {
                navDir = path === "" || p.startsWith(path + "/") || path === "/" ? 1 : -1;
                history = history.slice(0, historyIndex + 1).concat([p]);
                historyIndex = history.length - 1;
            }
            path = p;
            clearSelection();
            searchField.text = "";
            editingPath = false;
            viewArea.animateIn(navDir);
            focusView();
        }
        function back() {
            if (historyIndex <= 0) return;
            navDir = -1;
            historyIndex--;
            go(history[historyIndex], true);
        }
        function forward() {
            if (historyIndex >= history.length - 1) return;
            navDir = 1;
            historyIndex++;
            go(history[historyIndex], true);
        }
        function up() {
            if (path === "/") return;
            const from = path;
            go(parentOf(path));
            selected = ({ [from]: true });
        }
        // Path typed in the bar: only go there if it's a folder
        function tryGo(p) {
            p = normalize(p);
            checkDir.target = p;
            checkDir.running = true;
        }
        Process {
            id: checkDir
            property string target
            command: ["test", "-d", target]
            onExited: code => {
                if (code === 0) win.go(target);
                else win.toast("No such folder: " + win.prettyPath(target));
            }
        }

        function open(p, isDir) {
            if (isDir) go(p);
            else openFiles([p]);
        }
        function openSelected() {
            const paths = selectedPaths();
            if (paths.length === 1) {
                const i = indexOf(paths[0]);
                open(paths[0], i >= 0 && isDirAt(i));
                return;
            }
            openFiles(paths.filter(p => { const i = indexOf(p); return i >= 0 && !isDirAt(i); }));
        }

        // ---------- launching apps ----------
        // Open files in their default apps. Like xdg-open, except terminal apps (micro, vim…)
        // get a kitty window — xdg-open would start them with no terminal and they'd crash.
        property var pendingOpen: []
        function openFiles(paths) {
            if (paths.length === 0) return;
            pendingOpen = pendingOpen.concat(paths);
            if (!defaults.running) nextDefaults();
        }
        function nextDefaults() {
            if (pendingOpen.length === 0) return;
            defaults.files = pendingOpen;
            pendingOpen = [];
            defaults.running = true;
        }
        Process {
            id: defaults
            property var files: []
            command: ["sh", "-c", 'for f; do xdg-mime query default "$(xdg-mime query filetype "$f")" 2>/dev/null || echo; done', "sh"].concat(files)
            stdout: StdioCollector {
                onStreamFinished: {
                    const ids = text.split("\n");
                    defaults.files.forEach((f, i) => {
                        const id = (ids[i] ?? "").trim().replace(/\.desktop$/, "");
                        const entry = id ? DesktopEntries.byId(id) : null;
                        if (entry && entry.runInTerminal) win.launchApp(entry, [f]);
                        else Quickshell.execDetached(["xdg-open", f]);
                    });
                    win.nextDefaults();
                }
            }
        }
        // The app's Exec line with the files filled in (desktop entry field codes)
        function execArgs(entry, paths) {
            const out = [];
            const re = /"((?:\\.|[^"\\])*)"|(\S+)/g;
            let m;
            while ((m = re.exec(entry.execString)) !== null) {
                const tok = m[1] !== undefined ? m[1].replace(/\\(.)/g, "$1") : m[2];
                if (tok === "%F" || tok === "%U") { out.push(...paths); continue; }
                if (tok === "%f" || tok === "%u") { if (paths[0]) out.push(paths[0]); continue; }
                const t = tok.replace(/%[a-zA-Z]/g, "").replace(/%%/g, "%");
                if (t !== "") out.push(t);
            }
            return out;
        }
        function launchApp(entry, paths) {
            if (!entry.runInTerminal) {
                // gtk-launch passes the files the way the app expects
                Quickshell.execDetached(["gtk-launch", entry.id].concat(paths));
                return;
            }
            // Apps that take one file at a time get one window per file
            const one = /%[fu]/.test(entry.execString) && !/%[FU]/.test(entry.execString);
            for (const group of one ? paths.map(p => [p]) : [paths])
                Quickshell.execDetached(["kitty", "--directory", parentOf(group[0] ?? path), "--"].concat(execArgs(entry, group)));
        }
        function indexOf(p) {
            for (let i = 0; i < model.count; i++) if (pathAt(i) === p) return i;
            return -1;
        }

        // ---------- selection ----------
        function clearSelection() { selected = ({}); anchorIndex = -1; }
        function selectOnly(p) { selected = ({ [p]: true }); }
        function toggle(p) {
            const s = Object.assign({}, selected);
            if (s[p]) delete s[p]; else s[p] = true;
            selected = s;
        }
        function selectAll() {
            const s = {};
            for (let i = 0; i < model.count; i++) s[pathAt(i)] = true;
            selected = s;
        }
        function selectRange(to) {
            const from = anchorIndex < 0 ? to : anchorIndex;
            const s = {};
            for (let i = Math.min(from, to); i <= Math.max(from, to); i++) s[pathAt(i)] = true;
            selected = s;
        }
        function itemClicked(index, p, isDir, button, mods, x, y) {
            currentView().currentIndex = index;
            if (button === Qt.RightButton) {
                if (!selected[p]) { selectOnly(p); anchorIndex = index; }
                itemMenu(x, y);
                return;
            }
            if (button === Qt.MiddleButton) {
                if (isDir) go(p);
                return;
            }
            if (mods & Qt.ShiftModifier) { selectRange(index); return; }
            if (mods & Qt.ControlModifier) toggle(p);
            else selectOnly(p);
            anchorIndex = index;
        }

        // ---------- file operations ----------
        property var opQueue: []
        function run(cmd, okMsg, after) {
            opQueue.push({ cmd: cmd, okMsg: okMsg, after: after });
            if (!op.running) nextOp();
        }
        function nextOp() {
            const job = opQueue.shift();
            if (!job) return;
            op.job = job;
            op.command = job.cmd;
            op.running = true;
        }
        Process {
            id: op
            property var job: null
            stderr: StdioCollector { id: opErr }
            onExited: code => {
                const job = op.job;
                if (code === 0) {
                    if (job.okMsg) win.toast(job.okMsg);
                    if (job.after) job.after();
                } else {
                    const msg = code === 3 ? "That name is already taken" : opErr.text.trim().split("\n").pop();
                    win.toast(msg || "Something went wrong");
                }
                storage.refresh();
                win.nextOp();
            }
        }

        function plural(n, word) { return n + " " + word + (n === 1 ? "" : "s"); }

        function copy(cut) {
            const paths = selectedPaths();
            if (paths.length === 0) return;
            clipPaths = paths;
            clipCut = cut;
            Quickshell.execDetached(["wl-copy", "-t", "text/uri-list", paths.map(p => FileTypes.url(p)).join("\r\n")]);
            toast((cut ? "Cut " : "Copied ") + plural(paths.length, "item"));
        }
        function paste(into) {
            if (clipPaths.length === 0) return;
            const dest = into || path;
            const n = clipPaths.length;
            const cut = clipCut;
            run(["sh", Quickshell.shellDir + "/scripts/files-paste.sh", cut ? "cut" : "copy", dest].concat(clipPaths),
                (cut ? "Moved " : "Pasted ") + plural(n, "item"));
            if (cut) clipPaths = [];
        }
        function trash() {
            const paths = selectedPaths();
            if (paths.length === 0) return;
            if (inTrash) { deleteForever(); return; }
            clearSelection();
            run(["gio", "trash", "--"].concat(paths), "Moved " + plural(paths.length, "item") + " to Trash");
        }
        function deleteForever() {
            const paths = selectedPaths();
            if (paths.length === 0) return;
            dialog.ask({
                icon: "delete_forever", danger: true, confirm: "Delete",
                title: paths.length === 1 ? `Delete “${baseName(paths[0])}” forever?` : `Delete ${paths.length} items forever?`,
                body: "This can't be undone.",
                onAccept: () => {
                    clearSelection();
                    run(["rm", "-rf", "--"].concat(paths), "Deleted " + plural(paths.length, "item"));
                }
            });
        }
        function restore() {
            const paths = selectedPaths();
            clearSelection();
            run(["gio", "trash", "--restore"].concat(paths.map(p => "trash:///" + encodeURIComponent(baseName(p)))),
                "Restored " + plural(paths.length, "item"));
        }
        function emptyTrash() {
            dialog.ask({
                icon: "delete_sweep", danger: true, confirm: "Empty",
                title: "Empty the Trash?", body: "Everything in the Trash will be deleted forever.",
                onAccept: () => run(["gio", "trash", "--empty"], "Trash emptied")
            });
        }
        function rename() {
            const paths = selectedPaths();
            if (paths.length !== 1) return;
            const old = paths[0];
            dialog.ask({
                icon: "edit", title: "Rename", value: baseName(old), confirm: "Rename", selectStem: true,
                onAccept: name => {
                    const dest = join(parentOf(old), name);
                    if (dest === old) return;
                    run(["sh", "-c", '[ -e "$2" ] && exit 3; mv -- "$1" "$2"', "sh", old, dest], "", () => selectOnly(dest));
                }
            });
        }
        function newFolder() {
            if (searching) return;
            dialog.ask({
                icon: "create_new_folder", title: "New folder", value: "", placeholder: "Folder name", confirm: "Create",
                onAccept: name => {
                    const dest = join(path, name);
                    run(["sh", "-c", '[ -e "$1" ] && exit 3; mkdir -- "$1"', "sh", dest], "", () => selectOnly(dest));
                }
            });
        }
        function newFile() {
            if (searching) return;
            dialog.ask({
                icon: "note_add", title: "New file", value: "", placeholder: "File name", confirm: "Create",
                onAccept: name => {
                    const dest = join(path, name);
                    run(["sh", "-c", '[ -e "$1" ] && exit 3; : > "$1"', "sh", dest], "", () => selectOnly(dest));
                }
            });
        }
        function extract(p) {
            run(["sh", "-c", 'd="${2%.*}"; d="${d%.tar}"; mkdir -p -- "$d" && bsdtar -xf "$2" -C "$d"', "sh", path, p],
                "Extracted " + baseName(p));
        }
        function copyPath() {
            Quickshell.execDetached(["wl-copy", selectedPaths().join("\n") || path]);
            toast("Path copied");
        }
        function terminalHere(dir) { Quickshell.execDetached(["kitty", "--directory", dir || path]); }
        function setWallpaper(p) {
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/set-wallpaper.sh", p]);
            toast("Wallpaper set");
        }
        function isPinned(p) { return (Config.files.pinned ?? []).indexOf(p) >= 0; }
        function pin(p) {
            if (!isPinned(p)) Config.files.pinned = (Config.files.pinned ?? []).concat([p]);
        }
        function unpin(p) { Config.files.pinned = (Config.files.pinned ?? []).filter(x => x !== p); }

        // ---------- drag and drop ----------
        // Local paths from dropped URLs (ignores web links etc.)
        function dropPaths(urls) {
            return (urls ?? []).map(u => u.toString()).filter(u => u.startsWith("file://"))
                .map(u => normalize(decodeURIComponent(u.slice(7))));
        }
        // Can these be dropped into dest? (not into itself, not where they already are)
        function canDrop(urls, dest) {
            if (!dest) return false;
            const paths = dropPaths(urls);
            return paths.some(p => p !== dest && !dest.startsWith(p + "/") && parentOf(p) !== dest);
        }
        // Move by default; copy when the drag asks for it (Ctrl, or dragged from another app that only copies)
        function handleDrop(d, dest) {
            const paths = dropPaths(d.urls).filter(p => p !== dest && !dest.startsWith(p + "/") && parentOf(p) !== dest);
            if (paths.length === 0) return;
            const copy = d.proposedAction === Qt.CopyAction || !(d.supportedActions & Qt.MoveAction);
            d.accept(copy ? Qt.CopyAction : Qt.MoveAction);
            clearSelection();
            if (dest === trashDir) {
                run(["gio", "trash", "--"].concat(paths), "Moved " + plural(paths.length, "item") + " to Trash");
                return;
            }
            run(["sh", Quickshell.shellDir + "/scripts/files-paste.sh", copy ? "copy" : "cut", dest].concat(paths),
                (copy ? "Copied " : "Moved ") + plural(paths.length, "item") + " to " + (dest === home ? "Home" : baseName(dest)));
        }
        // The picture under the pointer while dragging: the file's icon, with a count badge
        property string dragImage: ""
        function prepareDragImage(p, name, isDir, count) {
            dragProxy.path = p;
            dragProxy.name = name;
            dragProxy.isDir = isDir;
            dragProxy.count = count;
            dragProxy.grabToImage(r => win.dragImage = r.url);
        }

        // ---------- drag-to-select ----------
        // Geometry of item i in the view's content coordinates
        function itemRect(v, i) {
            if (v === grid) {
                const c = i % grid.cols, r = Math.floor(i / grid.cols);
                return Qt.rect(c * grid.cellWidth + 4, r * grid.cellHeight + 4, grid.cellWidth - 8, grid.cellHeight - 8);
            }
            const h = listRowHeight + list.spacing;
            return Qt.rect(0, i * h, list.width, listRowHeight);
        }
        readonly property int listRowHeight: searching ? 56 : 50
        function updateBand() {
            const v = currentView();
            const a = band.start, b = band.cur;
            const x1 = Math.min(a.x, b.x), x2 = Math.max(a.x, b.x), y1 = Math.min(a.y, b.y), y2 = Math.max(a.y, b.y);
            // Only look at the rows the band covers
            const rowH = v === grid ? grid.cellHeight : listRowHeight + list.spacing;
            const perRow = v === grid ? grid.cols : 1;
            const first = Math.max(0, Math.floor(y1 / rowH) * perRow);
            const last = Math.min(model.count - 1, (Math.floor(y2 / rowH) + 1) * perRow - 1);
            const s = Object.assign({}, band.base);
            for (let i = first; i <= last; i++) {
                const r = itemRect(v, i);
                if (r.x < x2 && r.x + r.width > x1 && r.y < y2 && r.y + r.height > y1) s[pathAt(i)] = true;
            }
            selected = s;
        }

        // ---------- scrolling ----------
        // Smooth wheel scrolling (the views don't flick with the mouse, so drags can select / move files)
        function scrollBy(v, e) {
            const touchpad = e.pixelDelta.y !== 0;
            const dy = touchpad ? e.pixelDelta.y : e.angleDelta.y / 120 * 120;
            const min = v.originY - v.topMargin;
            const max = Math.max(min, v.originY + v.contentHeight + v.bottomMargin - v.height);
            const from = smoothScroll.running && smoothScroll.target === v ? smoothScroll.to : v.contentY;
            const to = Math.max(min, Math.min(max, from - dy));
            smoothScroll.stop();
            if (touchpad || Theme.animMs === 0) { v.contentY = to; return; }
            smoothScroll.target = v;
            smoothScroll.to = to;
            smoothScroll.start();
        }
        NumberAnimation {
            id: smoothScroll
            property: "contentY"
            duration: 220
            easing.type: Easing.OutCubic
        }

        // ---------- menus ----------
        function itemMenu(x, y) {
            const paths = selectedPaths();
            const one = paths.length === 1 ? paths[0] : "";
            const i = one ? indexOf(one) : -1;
            const dir = i >= 0 && isDirAt(i);
            const kind = one ? FileTypes.kind(baseName(one), dir) : "";
            menu.popup(x, y, [
                { icon: "open_in_new", text: "Open", hint: "Enter", action: () => openSelected() },
                { icon: "apps", text: "Open with…", action: () => openWith.ask(paths) },
                one && searching ? { icon: "folder_open", text: "Show in folder", action: () => { const f = one; go(parentOf(f)); selectOnly(f); } } : null,
                dir ? { icon: "terminal", text: "Open terminal here", action: () => terminalHere(one) } : null,
                dir ? (isPinned(one) ? { icon: "keep_off", text: "Unpin from sidebar", action: () => unpin(one) }
                                     : { icon: "keep", text: "Pin to sidebar", action: () => pin(one) }) : null,
                kind === "archive" ? { icon: "unarchive", text: "Extract here", action: () => extract(one) } : null,
                kind === "image" ? { icon: "wallpaper", text: "Set as wallpaper", action: () => setWallpaper(one) } : null,
                { separator: true },
                { icon: "content_cut", text: "Cut", hint: "Ctrl+X", action: () => copy(true) },
                { icon: "content_copy", text: "Copy", hint: "Ctrl+C", action: () => copy(false) },
                dir ? { icon: "content_paste", text: "Paste into folder", enabled: clipPaths.length > 0, action: () => paste(one) } : null,
                { icon: "link", text: "Copy path", action: () => copyPath() },
                { icon: "edit", text: "Rename", hint: "F2", enabled: !!one, action: () => rename() },
                { separator: true },
                inTrash ? { icon: "restore_from_trash", text: "Restore", action: () => restore() } : null,
                inTrash ? { icon: "delete_forever", text: "Delete forever", hint: "Del", danger: true, action: () => deleteForever() }
                        : { icon: "delete", text: "Move to Trash", hint: "Del", danger: true, action: () => trash() }
            ]);
        }
        function backgroundMenu(x, y) {
            clearSelection();
            menu.popup(x, y, [
                !searching ? { icon: "create_new_folder", text: "New folder", hint: "Ctrl+Shift+N", action: () => newFolder() } : null,
                !searching ? { icon: "note_add", text: "New file", action: () => newFile() } : null,
                { icon: "content_paste", text: "Paste", hint: "Ctrl+V", enabled: clipPaths.length > 0 && !searching, action: () => paste() },
                { icon: "select_all", text: "Select all", hint: "Ctrl+A", action: () => selectAll() },
                { separator: true },
                { icon: "terminal", text: "Open terminal here", hint: "F4", action: () => terminalHere() },
                { icon: "link", text: "Copy folder path", action: () => { clearSelection(); copyPath(); } },
                { icon: "visibility", text: "Show hidden files", hint: "Ctrl+H", checked: Config.files.showHidden,
                    action: () => Config.files.showHidden = !Config.files.showHidden },
                inTrash ? { separator: true } : null,
                inTrash ? { icon: "delete_sweep", text: "Empty Trash", danger: true, action: () => emptyTrash() } : null
            ]);
        }
        function sortMenu(x, y) {
            const s = Config.files.sortBy;
            const pick = v => () => Config.files.sortBy = v;
            menu.popup(x, y, [
                { icon: "sort_by_alpha", text: "Name", checked: s === "name", action: pick("name") },
                { icon: "schedule", text: "Modified", checked: s === "modified", action: pick("modified") },
                { icon: "straighten", text: "Size", checked: s === "size", action: pick("size") },
                { icon: "category", text: "Type", checked: s === "type", action: pick("type") },
                { separator: true },
                { icon: "swap_vert", text: "Reverse order", checked: Config.files.sortReversed,
                    action: () => Config.files.sortReversed = !Config.files.sortReversed }
            ]);
        }

        // ---------- snackbar ----------
        property string toastText: ""
        property bool toastShown: false
        function toast(t) {
            toastText = t;
            toastShown = true;
            toastTimer.restart();
        }
        Timer { id: toastTimer; interval: 3000; onTriggered: win.toastShown = false }

        function currentView() { return listMode ? list : grid; }
        function focusView() { currentView().forceActiveFocus(); }

        Component.onCompleted: go(Globals.filesPath || home)
        Connections {
            target: Globals
            function onFilesNavigate(p) { win.go(p); }
        }

        // ---------- models ----------
        FolderListModel {
            id: folderModel
            folder: win.path ? FileTypes.url(win.path) : ""
            showHidden: Config.files.showHidden
            showDirsFirst: true
            showDotAndDotDot: false
            caseSensitive: false
            sortCaseSensitive: false
            sortReversed: Config.files.sortReversed
            sortField: ({ name: FolderListModel.Name, modified: FolderListModel.Time,
                size: FolderListModel.Size, type: FolderListModel.Type })[Config.files.sortBy] ?? FolderListModel.Name
        }

        ListModel { id: searchModel }
        Timer { id: searchDelay; interval: 250; onTriggered: win.startSearch() }
        onQueryChanged: {
            clearSelection();
            searchModel.clear();
            searchDelay.restart();
        }
        function startSearch() {
            if (searchProc.running) {           // let the old search stop first
                searchProc.running = false;
                searchDelay.restart();
                return;
            }
            searchModel.clear();
            if (!searching) return;
            const pattern = "*" + query.replace(/[*?\[\]\\]/g, "\\$&") + "*";
            const skipHidden = Config.files.showHidden ? [] : ["(", "-name", ".*", "-prune", ")", "-o"];
            searchProc.forQuery = query;
            searchProc.command = ["find", path, "-mindepth", "1", "-maxdepth", "8"].concat(skipHidden)
                .concat(["-iname", pattern, "-printf", "%y\\t%s\\t%T@\\t%p\\n"]);
            searchProc.running = true;
        }
        Process {
            id: searchProc
            property string forQuery
            stdout: SplitParser {
                onRead: line => {
                    if (searchProc.forQuery !== win.query) return;
                    if (searchModel.count >= 500) { searchProc.running = false; return; }
                    const parts = line.split("\t");
                    if (parts.length < 4) return;
                    const p = parts.slice(3).join("\t");
                    searchModel.append({
                        fileName: p.substring(p.lastIndexOf("/") + 1), filePath: p, fileIsDir: parts[0] === "d",
                        fileSize: Number(parts[1]), fileModified: Number(parts[2]) * 1000
                    });
                }
            }
        }

        // ---------- sidebar data ----------
        readonly property var standardPlaces: [
            { name: "Home", icon: "home", path: home },
            { name: "Desktop", icon: "desktop_windows", path: home + "/Desktop" },
            { name: "Documents", icon: "description", path: home + "/Documents" },
            { name: "Downloads", icon: "download", path: home + "/Downloads" },
            { name: "Music", icon: "music_note", path: home + "/Music" },
            { name: "Pictures", icon: "image", path: home + "/Pictures" },
            { name: "Videos", icon: "movie", path: home + "/Videos" }
        ]
        property var existing: [home]
        Process {
            running: true
            command: ["sh", "-c", 'for d; do [ -d "$d" ] && echo "$d"; done', "sh"].concat(win.standardPlaces.map(p => p.path))
            stdout: StdioCollector { onStreamFinished: win.existing = text.split("\n").filter(l => l) }
        }
        readonly property var places: standardPlaces.filter(p => existing.indexOf(p.path) >= 0)
            .concat([{ name: "Trash", icon: "delete", path: trashDir }])
        readonly property var pinnedPlaces: (Config.files.pinned ?? []).map(p => ({ name: baseName(p), icon: "folder", path: p, pinned: true }))

        // Every drive with a filesystem, mounted or not (like Dolphin). Clicking an unmounted one
        // mounts it with udisks (internal drives may ask for your password) and opens it.
        property var drives: []
        // Partitions nobody wants to browse
        readonly property var hiddenPartTypes: ["EFI System", "Microsoft reserved", "Windows recovery environment", "BIOS boot"]
        // System mounts that are already covered by "File system"
        function systemMount(m) { return m === "/" || m === "/home" || m === "[SWAP]" || /^\/(boot|efi|var|usr|opt|srv|nix|snap)(\/|$)/.test(m); }
        Process {
            id: mounts
            running: true
            command: ["lsblk", "-J", "-b", "-o", "PATH,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS,PARTTYPENAME,RM,HOTPLUG,MODEL"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let tree;
                    try { tree = JSON.parse(text).blockdevices; } catch (e) { return; }
                    const out = [];
                    const walk = (list, disk) => {
                        for (const d of list ?? []) {
                            const isDisk = d.type === "disk";
                            const parent = isDisk ? d : disk;
                            const mps = (d.mountpoints ?? []).filter(m => m);
                            if (d.fstype && d.fstype !== "swap" && d.type !== "rom" || d.type === "rom" && mps.length) {
                                const hidden = win.hiddenPartTypes.indexOf(d.parttypename) >= 0 || mps.some(m => win.systemMount(m));
                                if (!hidden) {
                                    const removable = d.rm || d.hotplug || parent?.rm || parent?.hotplug;
                                    const size = FileTypes.size(Number(d.size));
                                    out.push({
                                        name: d.label || (d.parttypename === "Microsoft basic data" && d.fstype === "ntfs" && Number(d.size) > 100e9
                                            ? size + " Windows drive" : size + " drive"),
                                        icon: d.type === "rom" ? "album" : removable ? "usb" : "hard_drive",
                                        path: mps[0] ?? "",
                                        device: d.path,
                                        mounted: mps.length > 0,
                                        removable: !!removable,
                                        detail: `${size} · ${d.fstype}${parent?.model ? " · " + parent.model.trim() : ""}`
                                    });
                                }
                            }
                            walk(d.children, parent);
                        }
                    };
                    walk(tree, null);
                    // Mounted first, then by name
                    out.sort((a, b) => (b.mounted - a.mounted) || a.name.localeCompare(b.name));
                    if (JSON.stringify(out) !== JSON.stringify(win.drives)) win.drives = out;
                }
            }
        }
        Timer { interval: 3000; running: win.visible; repeat: true; onTriggered: mounts.running = true }

        // Mount a drive, then open it
        function mountAndOpen(d) {
            if (mountProc.running) return;
            mountProc.drive = d;
            mountProc.running = true;
            toast("Mounting " + d.name + "…");
        }
        Process {
            id: mountProc
            property var drive: null
            command: ["udisksctl", "mount", "-b", drive?.device ?? ""]
            stdout: StdioCollector { id: mountOut }
            stderr: StdioCollector { id: mountErr }
            onExited: code => {
                mounts.running = true;
                // "Mounted /dev/sda1 at /run/media/you/Backup 4"
                const at = mountOut.text.match(/ at (.+?)\.?\s*$/);
                if (code === 0 && at) { win.toastShown = false; win.go(at[1]); return; }
                const err = mountErr.text.trim();
                if (/already mounted/i.test(err)) { mounts.running = true; return; }
                win.toast(/NotAuthorized|dismissed/i.test(err) ? "Mounting was cancelled"
                    : /hibernat|unclean|dirty/i.test(err) ? "Windows didn't shut down fully (Fast Startup), so this drive can't be opened safely"
                    : "Couldn't mount " + (mountProc.drive?.name ?? "drive") + (err ? ": " + err.split("\n").pop() : ""));
            }
        }
        function unmount(d) {
            if (path === d.path || path.startsWith(d.path + "/")) go(home);
            run(["udisksctl", "unmount", "-b", d.device], "Unmounted " + d.name, () => {
                if (d.removable) Quickshell.execDetached(["udisksctl", "power-off", "-b", d.device]);
                mounts.running = true;
            });
        }
        function openPlace(d) {
            if (d.device !== undefined && !d.mounted) mountAndOpen(d);
            else go(d.path);
        }

        readonly property var devices: [{ name: "File system", icon: "hard_drive", path: "/" }].concat(drives)

        // The sidebar entry for the current folder: the longest matching place
        readonly property string activePlace: {
            let best = "";
            for (const p of places.concat(pinnedPlaces).concat(devices))
                if (p.path && (path === p.path || path.startsWith(p.path === "/" ? "/" : p.path + "/")) && p.path.length > best.length) best = p.path;
            return best;
        }

        // Free space on the current drive
        QtObject {
            id: storage
            property real total: 0
            property real free: 0
            function refresh() {
                if (!win.path) return;
                df.command = ["df", "-B1", "--output=size,avail", win.path];
                df.running = true;
            }
        }
        onPathChanged: storage.refresh()
        Process {
            id: df
            stdout: StdioCollector {
                onStreamFinished: {
                    const nums = (text.split("\n")[1] ?? "").trim().split(/\s+/).map(Number);
                    if (nums.length === 2) { storage.total = nums[0]; storage.free = nums[1]; }
                }
            }
        }

        // ---------- keyboard ----------
        Shortcut { sequences: ["Alt+Left", "Backspace", "Back"]; onActivated: win.back() }
        Shortcut { sequences: ["Alt+Right", "Forward"]; onActivated: win.forward() }
        Shortcut { sequence: "Alt+Up"; onActivated: win.up() }
        Shortcut { sequence: "Alt+Home"; onActivated: win.go(win.home) }
        Shortcut { sequence: "Ctrl+L"; onActivated: win.editingPath = true }
        Shortcut { sequence: "Ctrl+F"; onActivated: searchField.forceActiveFocus() }
        Shortcut { sequence: "Ctrl+H"; onActivated: Config.files.showHidden = !Config.files.showHidden }
        Shortcut { sequence: "Ctrl+A"; onActivated: win.selectAll() }
        Shortcut { sequence: "Ctrl+C"; onActivated: win.copy(false) }
        Shortcut { sequence: "Ctrl+X"; onActivated: win.copy(true) }
        Shortcut { sequence: "Ctrl+V"; onActivated: if (!win.searching) win.paste() }
        Shortcut { sequence: "F2"; onActivated: win.rename() }
        Shortcut { sequence: "Delete"; onActivated: win.trash() }
        Shortcut { sequence: "Shift+Delete"; onActivated: win.deleteForever() }
        Shortcut { sequence: "Ctrl+Shift+N"; onActivated: win.newFolder() }
        Shortcut { sequence: "F4"; onActivated: win.terminalHere() }
        Shortcut { sequence: "Ctrl+1"; onActivated: Config.files.view = "grid" }
        Shortcut { sequence: "Ctrl+2"; onActivated: Config.files.view = "list" }
        Shortcut { sequences: ["Ctrl+=", "Ctrl++"]; onActivated: win.zoom(1) }
        Shortcut { sequence: "Ctrl+-"; onActivated: win.zoom(-1) }
        Shortcut { sequences: ["Ctrl+W", "Ctrl+Q"]; onActivated: Globals.filesOpen = false }
        Shortcut {
            sequence: "Escape"
            onActivated: {
                if (menu.open) menu.close();
                else if (dialog.open) dialog.close();
                else if (openWith.open) openWith.close();
                else if (win.editingPath) win.editingPath = false;
                else if (win.searching) { searchField.text = ""; win.focusView(); }
                else win.clearSelection();
            }
        }
        function zoom(step) {
            Config.files.iconSize = Math.max(48, Math.min(160, Config.files.iconSize + step * 16));
        }

        // Mouse back / forward buttons
        MouseArea {
            anchors.fill: parent
            z: 100
            acceptedButtons: Qt.BackButton | Qt.ForwardButton
            onPressed: mouse => mouse.button === Qt.BackButton ? win.back() : win.forward()
        }

        // ================= layout =================
        WindowTitleBar {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            windowTitle: win.title
            sidebarWidth: 236
            sidebarColor: Theme.bg1
            onCloseRequested: Globals.filesOpen = false
        }

        RowLayout {
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            // ---------- sidebar (M3 navigation drawer) ----------
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 236
                color: Theme.bg1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 0

                    RowLayout {
                        Layout.leftMargin: 10
                        Layout.topMargin: 8
                        Layout.bottomMargin: 16
                        spacing: 10
                        Text {
                            text: "folder_open"
                            color: Theme.accent
                            font.family: Theme.iconFont
                            font.variableAxes: Theme.iconAxesWith(1)
                            font.pixelSize: 26
                        }
                        Text {
                            text: "Files"
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 6
                            font.weight: Font.Black
                        }
                    }

                    // Extended FAB
                    Rectangle {
                        id: fab
                        Layout.bottomMargin: 14
                        implicitWidth: fabRow.implicitWidth + 36
                        implicitHeight: 52
                        radius: fabArea.pressed ? 12 : 16
                        Behavior on radius { NumberAnimation { duration: 120 } }
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        opacity: win.searching ? 0.38 : 1
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.accent
                            opacity: fabArea.pressed ? 0.12 : fabArea.containsMouse ? 0.08 : 0
                        }
                        RowLayout {
                            id: fabRow
                            anchors.centerIn: parent
                            spacing: 10
                            Text {
                                text: "create_new_folder"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                property real fill: fabArea.containsMouse ? 1 : 0
                                Behavior on fill { NumberAnimation { duration: 200 } }
                                font.variableAxes: Theme.iconAxesWith(fill)
                                font.pixelSize: Theme.fontSize + 6
                            }
                            Text {
                                text: "New folder"
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.DemiBold
                            }
                        }
                        MouseArea {
                            id: fabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.newFolder()
                        }
                    }

                    Flickable {
                        id: sideFlick
                        SmoothWheel { flick: sideFlick }
                        MScrollBar { flick: sideFlick }
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: nav.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Item {
                            id: nav
                            width: parent.width
                            implicitHeight: navCol.implicitHeight
                            property Item activeItem: null

                            // The sliding active pill
                            Rectangle {
                                id: pill
                                property bool ready: false
                                visible: nav.activeItem !== null
                                x: 0
                                width: nav.width
                                y: nav.activeItem ? nav.activeItem.y : 0
                                height: 44
                                radius: 22
                                color: Theme.accent
                                Behavior on y {
                                    enabled: pill.ready
                                    NumberAnimation { duration: Theme.animMs * 1.2; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel }
                                }
                                Timer { running: true; interval: 50; onTriggered: pill.ready = true }
                            }

                            Column {
                                id: navCol
                                width: parent.width
                                spacing: 2

                                NavHeader { text: "Places" }
                                Repeater { model: win.places; delegate: navItemComp }
                                NavHeader { text: "Pinned"; visible: win.pinnedPlaces.length > 0 }
                                Repeater { model: win.pinnedPlaces; delegate: navItemComp }
                                NavHeader { text: "Devices" }
                                Repeater { model: win.devices; delegate: navItemComp }
                            }
                        }
                    }

                    // Storage of the current drive (M3 linear progress)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 10
                        visible: storage.total > 0
                        spacing: 8
                        RowLayout {
                            spacing: 8
                            Text {
                                text: "storage"
                                color: Theme.fg2
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: Theme.fontSize + 1
                            }
                            Text {
                                text: FileTypes.size(storage.free) + " free of " + FileTypes.size(storage.total)
                                color: Theme.fg2
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            readonly property real used: storage.total > 0 ? 1 - storage.free / storage.total : 0
                            Rectangle {
                                id: usedBar
                                height: parent.height
                                radius: 3
                                width: Math.max(6, (parent.width - 4) * parent.used)
                                color: parent.used > 0.9 ? Theme.red : Theme.accent
                                Behavior on width { NumberAnimation { duration: Theme.animMs * 2; easing.type: Easing.OutCubic } }
                            }
                            Rectangle {
                                anchors.right: parent.right
                                x: usedBar.width + 4
                                width: parent.width - usedBar.width - 4
                                height: parent.height
                                radius: 3
                                color: Theme.bg2
                            }
                        }
                    }
                }
            }

            // ---------- main area ----------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Top app bar
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 12
                    Layout.bottomMargin: 6
                    spacing: 4

                    MIconButton { icon: "arrow_back"; enabled: win.historyIndex > 0; onClicked: win.back() }
                    MIconButton { icon: "arrow_forward"; enabled: win.historyIndex < win.history.length - 1; onClicked: win.forward() }
                    MIconButton { icon: "arrow_upward"; enabled: win.path !== "/"; onClicked: win.up() }

                    // Breadcrumbs / path field
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        implicitHeight: 44
                        radius: 22
                        color: Theme.bg1
                        border.width: pathInput.activeFocus ? 2 : 0
                        border.color: Theme.accent

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: win.editingPath = true
                        }

                        Flickable {
                            id: crumbFlick
                            visible: !win.editingPath
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            contentWidth: crumbRow.implicitWidth
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentWidth > width
                            onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
                            onWidthChanged: contentX = Math.max(0, contentWidth - width)

                            Row {
                                id: crumbRow
                                height: parent.height
                                spacing: 0

                                Repeater {
                                    model: {
                                        const p = win.path;
                                        const inside = r => p === r || p.startsWith(r + "/");
                                        // The crumbs start at Home, a drive, or the file system root
                                        const drive = win.drives.find(d => d.path && inside(d.path));
                                        const root = drive ? { label: drive.name, icon: drive.icon, path: drive.path }
                                            : inside(win.home) ? { label: "Home", icon: "home", path: win.home }
                                            : { label: "", icon: "hard_drive", path: "/" };
                                        const out = [root];
                                        const rest = root.path === "/" ? p : p.slice(root.path.length);
                                        let acc = root.path === "/" ? "" : root.path;
                                        for (const part of rest.split("/").filter(s => s)) {
                                            acc += "/" + part;
                                            out.push({ label: part, icon: "", path: acc });
                                        }
                                        return out;
                                    }

                                    Row {
                                        id: crumb
                                        required property var modelData
                                        required property int index
                                        readonly property bool last: modelData.path === win.path
                                        height: crumbRow.height

                                        Text {
                                            visible: crumb.index > 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "chevron_right"
                                            color: Theme.fg2
                                            font.family: Theme.iconFont
                                            font.pixelSize: Theme.fontSize + 2
                                        }
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: 32
                                            width: crumbContent.implicitWidth + 20
                                            radius: 16
                                            color: crumb.last ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : "transparent"
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                color: Theme.fg1
                                                opacity: crumbArea.pressed ? 0.12 : crumbArea.containsMouse ? 0.08 : 0
                                            }
                                            Row {
                                                id: crumbContent
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text {
                                                    visible: crumb.modelData.icon !== ""
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: crumb.modelData.icon
                                                    color: crumb.last ? Theme.accent : Theme.fg2
                                                    font.family: Theme.iconFont
                                                    font.variableAxes: Theme.iconAxesWith(crumb.last ? 1 : 0)
                                                    font.pixelSize: Theme.fontSize + 2
                                                }
                                                Text {
                                                    visible: text !== ""
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: crumb.modelData.label
                                                    color: crumb.last ? Theme.accent : Theme.fg1
                                                    font.family: Theme.font
                                                    font.pixelSize: Theme.fontSize - 1
                                                    font.weight: crumb.last ? Font.DemiBold : Font.Normal
                                                }
                                            }
                                            MouseArea {
                                                id: crumbArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.go(crumb.modelData.path)
                                            }
                                            // Drop on a crumb: move / copy into that parent folder
                                            border.width: crumbDrop.containsDrag && crumbDrop.valid ? 2 : 0
                                            border.color: Theme.accent
                                            DropArea {
                                                id: crumbDrop
                                                anchors.fill: parent
                                                keys: ["text/uri-list"]
                                                property bool valid: false
                                                onEntered: d => { valid = win.canDrop(d.urls, crumb.modelData.path); d.accepted = valid; }
                                                onExited: valid = false
                                                onDropped: d => { valid = false; win.handleDrop(d, crumb.modelData.path); }
                                            }
                                            Timer {
                                                running: crumbDrop.containsDrag && !crumb.last
                                                interval: 900
                                                onTriggered: win.go(crumb.modelData.path)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        TextInput {
                            id: pathInput
                            visible: win.editingPath
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            color: Theme.fg1
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.bg0
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            Keys.onReturnPressed: win.tryGo(text)
                            Keys.onEnterPressed: win.tryGo(text)
                            Keys.onEscapePressed: { win.editingPath = false; win.focusView(); }
                            onActiveFocusChanged: if (!activeFocus) win.editingPath = false
                        }
                    }

                    // Search bar
                    Rectangle {
                        Layout.preferredWidth: searchField.activeFocus || win.searching ? 300 : 220
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
                        Layout.leftMargin: 6
                        implicitHeight: 44
                        radius: 22
                        color: Theme.bg1
                        border.width: searchField.activeFocus ? 2 : 0
                        border.color: Theme.accent

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: searchField.forceActiveFocus()
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 6
                            spacing: 8
                            Text {
                                id: searchIcon
                                text: searchProc.running ? "progress_activity" : "search"
                                color: searchField.activeFocus ? Theme.accent : Theme.fg2
                                font.family: Theme.iconFont
                                font.variableAxes: Theme.iconAxes
                                font.pixelSize: Theme.fontSize + 4
                                RotationAnimation on rotation {
                                    running: searchProc.running
                                    from: 0; to: 360; duration: 900; loops: Animation.Infinite
                                    onRunningChanged: if (!running) searchIcon.rotation = 0
                                }
                            }
                            TextInput {
                                id: searchField
                                Layout.fillWidth: true
                                clip: true
                                color: Theme.fg1
                                selectionColor: Theme.accent
                                selectedTextColor: Theme.bg0
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                onTextChanged: win.query = text.trim()
                                Keys.onEscapePressed: { text = ""; win.focusView(); }
                                Keys.onDownPressed: win.focusView()
                                Keys.onReturnPressed: win.focusView()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: searchField.text === ""
                                    text: "Search " + (win.path === win.home ? "Home" : win.baseName(win.path))
                                    color: Theme.fg2
                                    font: searchField.font
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                            MIconButton {
                                size: 32
                                icon: "close"
                                visible: searchField.text !== ""
                                onClicked: { searchField.text = ""; win.focusView(); }
                            }
                        }
                    }

                    // View toggle (M3 connected button group)
                    Row {
                        Layout.leftMargin: 8
                        spacing: 2
                        Repeater {
                            model: [["grid", "grid_view"], ["list", "view_list"]]
                            Rectangle {
                                id: seg
                                required property var modelData
                                required property int index
                                readonly property bool on: Config.files.view === modelData[0]
                                width: on ? 52 : 44
                                height: 40
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                radius: on ? 20 : 8
                                topLeftRadius: index === 0 || on ? 20 : 6
                                bottomLeftRadius: index === 0 || on ? 20 : 6
                                topRightRadius: index === 1 || on ? 20 : 6
                                bottomRightRadius: index === 1 || on ? 20 : 6
                                color: on ? Theme.accent : Theme.bg1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: seg.on ? Theme.bg0 : Theme.fg1
                                    opacity: segArea.pressed ? 0.12 : segArea.containsMouse ? 0.08 : 0
                                }
                                CenteredIcon {
                                    text: seg.modelData[1]
                                    color: seg.on ? Theme.bg0 : Theme.fg1
                                    size: 20
                                    fill: seg.on ? 1 : 0
                                }
                                MouseArea {
                                    id: segArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.files.view = seg.modelData[0]
                                }
                            }
                        }
                    }
                    MIconButton {
                        id: sortBtn
                        Layout.leftMargin: 4
                        icon: "sort"
                        onClicked: {
                            const p = sortBtn.mapToItem(null, sortBtn.width, sortBtn.height + 4);
                            win.sortMenu(p.x - 248, p.y);
                        }
                    }
                    MIconButton {
                        id: moreBtn
                        icon: "more_vert"
                        onClicked: {
                            const p = moreBtn.mapToItem(null, moreBtn.width, moreBtn.height + 4);
                            win.menu_more(p.x - 248, p.y);
                        }
                    }
                }

                // Search heading
                RowLayout {
                    visible: win.searching
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.topMargin: 4
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: `Results for “${win.query}” in ${win.prettyPath(win.path)}`
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        elide: Text.ElideMiddle
                    }
                }

                // List header (sortable columns)
                RowLayout {
                    visible: win.listMode && !win.searching
                    Layout.fillWidth: true
                    Layout.leftMargin: 26
                    Layout.rightMargin: 34
                    Layout.topMargin: 4
                    spacing: 14
                    HeaderCell { Layout.fillWidth: true; label: "Name"; key: "name"; Layout.leftMargin: 46 }
                    HeaderCell { Layout.preferredWidth: 170; label: "Modified"; key: "modified" }
                    HeaderCell { Layout.preferredWidth: 80; label: "Size"; key: "size"; alignRight: true }
                }

                // Files
                Item {
                    id: viewArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    property real slideX: 0
                    HoverHandler { id: viewHover }
                    function animateIn(dir) {
                        enter.stop();
                        if (Theme.animMs === 0) return;
                        slideX = dir * 36;
                        opacity = 0;
                        enter.start();
                    }
                    ParallelAnimation {
                        id: enter
                        NumberAnimation { target: viewArea; property: "slideX"; to: 0; duration: Theme.animMs * 1.2; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel }
                        NumberAnimation { target: viewArea; property: "opacity"; to: 1; duration: Theme.animMs * 0.8; easing.type: Easing.OutCubic }
                    }

                    // Drops on empty space go into the current folder (also from other apps)
                    DropArea {
                        id: folderDrop
                        anchors.fill: parent
                        enabled: !win.searching
                        keys: ["text/uri-list"]
                        property bool valid: false
                        onEntered: d => { valid = win.canDrop(d.urls, win.path); d.accepted = valid; }
                        onExited: valid = false
                        onDropped: d => { valid = false; win.handleDrop(d, win.path); }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 24
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
                        border.width: 2
                        border.color: Theme.accent
                        opacity: folderDrop.containsDrag && folderDrop.valid ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.fill: parent
                        transform: Translate { x: viewArea.slideX }

                        // Empty space: click to deselect, drag to select, right-click for the folder menu
                        MouseArea {
                            id: band
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            property point start
                            property point cur
                            property point mouse
                            property var base: ({})
                            property bool active: false

                            function contentPoint(x, y) {
                                const v = win.currentView();
                                return Qt.point(x + v.contentX, y + v.contentY);
                            }
                            onPressed: m => {
                                win.focusView();
                                if (m.button !== Qt.LeftButton) return;
                                start = contentPoint(m.x, m.y);
                                cur = start;
                                mouse = Qt.point(m.x, m.y);
                                base = m.modifiers & (Qt.ControlModifier | Qt.ShiftModifier) ? Object.assign({}, win.selected) : {};
                                active = false;
                            }
                            onPositionChanged: m => {
                                mouse = Qt.point(m.x, m.y);
                                cur = contentPoint(m.x, m.y);
                                if (!active && Math.hypot(cur.x - start.x, cur.y - start.y) > 6) active = true;
                                if (active) win.updateBand();
                            }
                            onReleased: m => {
                                if (m.button === Qt.LeftButton && !active && !(m.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)))
                                    win.clearSelection();
                                active = false;
                            }
                            onClicked: m => {
                                if (m.button !== Qt.RightButton) return;
                                const p = mapToItem(null, m.x, m.y);
                                win.backgroundMenu(p.x, p.y);
                            }

                            // Scroll while dragging near the top / bottom edge
                            Timer {
                                running: band.active
                                interval: 16
                                repeat: true
                                onTriggered: {
                                    const v = win.currentView();
                                    const edge = 36;
                                    let dy = 0;
                                    if (band.mouse.y < edge) dy = -(edge - band.mouse.y) / 2;
                                    else if (band.mouse.y > band.height - edge) dy = (band.mouse.y - band.height + edge) / 2;
                                    if (dy === 0) return;
                                    const min = v.originY - v.topMargin;
                                    const max = Math.max(min, v.originY + v.contentHeight + v.bottomMargin - v.height);
                                    v.contentY = Math.max(min, Math.min(max, v.contentY + dy));
                                    band.cur = band.contentPoint(band.mouse.x, band.mouse.y);
                                    win.updateBand();
                                }
                            }
                        }

                        GridView {
                            id: grid
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            visible: !win.listMode
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.6 } }
                            model: win.listMode ? null : win.model
                            readonly property int cols: Math.max(1, Math.floor(width / (Config.files.iconSize + 52)))
                            cellWidth: Math.floor(width / cols)
                            cellHeight: Config.files.iconSize + 78
                            Behavior on cellHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            clip: true
                            topMargin: 4
                            bottomMargin: 16
                            currentIndex: -1
                            keyNavigationEnabled: true
                            highlightFollowsCurrentItem: false
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: false
                            onCurrentIndexChanged: win.keyMoved(currentIndex)
                            Keys.onPressed: event => win.viewKey(event)

                            delegate: FileItem {
                                width: grid.cellWidth
                                height: grid.cellHeight
                                explorer: win
                                iconSize: Config.files.iconSize
                            }

                            WheelHandler {
                                acceptedModifiers: Qt.ControlModifier
                                onWheel: event => win.zoom(event.angleDelta.y > 0 ? 1 : -1)
                            }
                            WheelHandler {
                                acceptedModifiers: Qt.NoModifier
                                onWheel: event => win.scrollBy(grid, event)
                            }
                            MScrollBar { flick: grid }
                        }

                        ListView {
                            id: list
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            visible: win.listMode
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.6 } }
                            model: win.listMode ? win.model : null
                            clip: true
                            spacing: 2
                            topMargin: 4
                            bottomMargin: 16
                            currentIndex: -1
                            keyNavigationEnabled: true
                            highlightFollowsCurrentItem: false
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: false
                            onCurrentIndexChanged: win.keyMoved(currentIndex)
                            Keys.onPressed: event => win.viewKey(event)

                            delegate: FileItem {
                                width: list.width
                                height: win.listRowHeight
                                explorer: win
                                listMode: true
                                showFolder: win.searching
                            }

                            WheelHandler {
                                acceptedModifiers: Qt.NoModifier
                                onWheel: event => win.scrollBy(list, event)
                            }
                            MScrollBar { flick: list }
                        }

                        // Selection rectangle
                        Rectangle {
                            visible: band.active
                            readonly property var v: win.currentView()
                            x: band.x + Math.min(band.start.x, band.cur.x) - v.contentX
                            y: Math.min(band.start.y, band.cur.y) - v.contentY
                            width: Math.abs(band.cur.x - band.start.x)
                            height: Math.abs(band.cur.y - band.start.y)
                            radius: 8
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                            border.width: 1
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.7)
                        }
                    }

                    // Empty states
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: win.model.count === 0 && !(win.searching && (searchProc.running || searchDelay.running))
                            && (win.searching || folderModel.status === FolderListModel.Ready)
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animMs } }
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 96
                            implicitHeight: 96
                            radius: 32
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                            CenteredIcon {
                                text: win.searching ? "search_off" : win.inTrash ? "delete" : "folder_open"
                                color: Theme.accent
                                size: 44
                                fill: 1
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: win.searching ? "No results" : win.inTrash ? "Trash is empty" : "This folder is empty"
                            color: Theme.fg1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 3
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: !win.searching && !win.inTrash
                            text: "Right-click to create something, or paste here"
                            color: Theme.fg2
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                }

                // Status bar
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 16
                    Layout.preferredHeight: 36
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        text: {
                            if (win.selectedCount > 0) {
                                let bytes = 0, files = 0;
                                for (let i = 0; i < win.model.count; i++) {
                                    if (win.selected[win.pathAt(i)] && !win.isDirAt(i)) { bytes += Number(win.sizeAt(i)); files++; }
                                }
                                return win.plural(win.selectedCount, "item") + " selected" + (files > 0 ? " · " + FileTypes.size(bytes) : "");
                            }
                            if (win.searching) return searchProc.running ? "Searching…" : win.plural(win.model.count, "result") + (win.model.count >= 500 ? " (showing the first 500)" : "");
                            return win.plural(win.model.count, "item");
                        }
                    }
                    Text {
                        visible: win.clipPaths.length > 0
                        text: (win.clipCut ? "content_cut" : "content_copy")
                        color: Theme.fg2
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        visible: win.clipPaths.length > 0
                        text: win.plural(win.clipPaths.length, "item") + " on clipboard"
                        color: Theme.fg2
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                    }
                    // Zoom slider for the grid
                    Text {
                        visible: !win.listMode
                        text: "zoom_in"
                        color: Theme.fg2
                        font.family: Theme.iconFont
                        font.variableAxes: Theme.iconAxes
                        font.pixelSize: Theme.fontSize
                    }
                    MSlider {
                        visible: !win.listMode
                        Layout.preferredWidth: 110
                        trackHeight: 8
                        trackColor: Theme.bg2
                        value: (Config.files.iconSize - 48) / 112
                        onMoved: v => Config.files.iconSize = 48 + Math.round(v * 7) * 16
                    }
                }
            }
        }

        // Keyboard handling for the file views
        property bool keyNav: false
        function viewKey(event) {
            const ctrl = event.modifiers & (Qt.ControlModifier | Qt.AltModifier);
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                openSelected();
                event.accepted = true;
            } else if ([Qt.Key_Up, Qt.Key_Down, Qt.Key_Left, Qt.Key_Right, Qt.Key_Home, Qt.Key_End, Qt.Key_PageUp, Qt.Key_PageDown].indexOf(event.key) >= 0) {
                keyNav = true;
                if (currentView().currentIndex < 0 && model.count > 0) {
                    currentView().currentIndex = 0;
                    event.accepted = true;
                }
            } else if (!ctrl && event.text.length === 1 && event.text > " " && event.text !== "\x7f") {
                // Typing starts a search
                searchField.forceActiveFocus();
                searchField.text += event.text;
                event.accepted = true;
            }
        }
        function keyMoved(i) {
            if (!keyNav || i < 0) return;
            keyNav = false;
            const p = pathAt(i);
            selectOnly(p);
            anchorIndex = i;
            currentView().positionViewAtIndex(i, GridView.Contain);
        }
        function menu_more(x, y) {
            menu.popup(x, y, [
                { icon: "visibility", text: "Show hidden files", hint: "Ctrl+H", checked: Config.files.showHidden,
                    action: () => Config.files.showHidden = !Config.files.showHidden },
                { icon: "photo", text: "Show previews", checked: Config.files.thumbnails,
                    action: () => Config.files.thumbnails = !Config.files.thumbnails },
                { separator: true },
                { icon: "note_add", text: "New file", enabled: !searching, action: () => newFile() },
                { icon: "terminal", text: "Open terminal here", hint: "F4", action: () => terminalHere() },
                { icon: "open_in_new", text: "Open in default app", action: () => Quickshell.execDetached(["xdg-open", path]) }
            ]);
        }
        property bool editingPath: false
        onEditingPathChanged: if (editingPath) {
            pathInput.text = path;
            pathInput.forceActiveFocus();
            pathInput.selectAll();
        }

        // Offscreen picture used as the drag image
        Item {
            id: dragProxy
            property string path
            property string name
            property bool isDir
            property int count: 1
            x: -200
            y: 0
            width: 72
            height: 72
            FileIcon {
                anchors.fill: parent
                anchors.margins: 6
                size: 60
                path: dragProxy.path
                name: dragProxy.name
                isDir: dragProxy.isDir
                active: true
            }
            Rectangle {
                visible: dragProxy.count > 1
                anchors.right: parent.right
                anchors.top: parent.top
                width: Math.max(24, countLabel.implicitWidth + 12)
                height: 24
                radius: 12
                color: Theme.accent
                Text {
                    id: countLabel
                    anchors.centerIn: parent
                    text: dragProxy.count
                    color: Theme.bg0
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Font.Bold
                }
            }
        }

        WindowResizeHandles { active: !titleBar.maximized }

        // Overlays
        Menu { id: menu }
        Dialog { id: dialog }
        OpenWithDialog { id: openWith; explorer: win }

        // M3 snackbar
        Rectangle {
            z: 70
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.toastShown ? parent.height - height - 52 : parent.height + 8
            Behavior on y { NumberAnimation { duration: Theme.animMs * 1.2; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.emphasizedDecel } }
            opacity: win.toastShown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animMs * 0.6 } }
            width: Math.min(toastLabel.implicitWidth + 40, parent.width - 48)
            height: 48
            radius: 12
            color: Theme.fg1
            Text {
                id: toastLabel
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                verticalAlignment: Text.AlignVCenter
                text: win.toastText
                color: Theme.bg0
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }
        }

        // ---------- inline components ----------
        component NavHeader: Text {
            width: parent.width
            topPadding: 14
            bottomPadding: 6
            leftPadding: 16
            color: Theme.fg2
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.weight: Font.DemiBold
        }

        // Sidebar entry (a Component, not an inline component, so it can see win / nav / menu)
        Component {
            id: navItemComp
          Item {
            id: navItem
            required property var modelData
            readonly property bool active: modelData.path !== "" && win.activePlace === modelData.path
            // A drive that isn't mounted yet: dimmed, mounts on click
            readonly property bool unmounted: modelData.device !== undefined && !modelData.mounted
            readonly property bool mounting: mountProc.running && mountProc.drive?.device === modelData.device
            width: navCol.width
            height: 44
            onActiveChanged: if (active) nav.activeItem = navItem
            Component.onCompleted: if (active) nav.activeItem = navItem
            Component.onDestruction: if (nav.activeItem === navItem) nav.activeItem = null

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: navItem.active ? Theme.bg0 : Theme.fg1
                opacity: navArea.pressed ? 0.12 : navArea.containsMouse ? 0.08 : 0
            }
            // Drop target: move / copy here (Trash: move to Trash)
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                border.width: 2
                border.color: Theme.accent
                opacity: navDrop.containsDrag && navDrop.valid ? 1 : 0
                scale: opacity > 0 ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }
            DropArea {
                id: navDrop
                anchors.fill: parent
                keys: ["text/uri-list"]
                property bool valid: false
                onEntered: d => { valid = win.canDrop(d.urls, navItem.modelData.path); d.accepted = valid; }
                onExited: valid = false
                onDropped: d => { valid = false; win.handleDrop(d, navItem.modelData.path); }
            }
            Timer {
                running: navDrop.containsDrag && navItem.modelData.path !== "" && navItem.modelData.path !== win.trashDir
                interval: 900
                onTriggered: win.go(navItem.modelData.path)
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 6
                spacing: 12
                Text {
                    id: navIcon
                    Layout.preferredWidth: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: navItem.mounting ? "progress_activity" : navItem.modelData.icon
                    RotationAnimation on rotation {
                        running: navItem.mounting
                        from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        onRunningChanged: if (!running) navIcon.rotation = 0
                    }
                    color: navItem.active ? Theme.bg0 : Theme.fg1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    font.family: Theme.iconFont
                    property real fill: navItem.active || navArea.containsMouse ? 1 : 0
                    Behavior on fill { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    font.variableAxes: Theme.iconAxesWith(fill)
                    font.pixelSize: Theme.fontSize + 3
                }
                Text {
                    Layout.fillWidth: true
                    text: navItem.modelData.name
                    opacity: navItem.unmounted && !navArea.containsMouse ? 0.6 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    color: navItem.active ? Theme.bg0 : Theme.fg1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: navItem.active ? Font.Bold : Font.Medium
                    elide: Text.ElideRight
                }
                MIconButton {
                    visible: navItem.modelData.device !== undefined && navItem.modelData.mounted && navArea.containsMouse
                    size: 32
                    icon: "eject"
                    onClicked: win.unmount(navItem.modelData)
                }
            }
            MouseArea {
                id: navArea
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const d = navItem.modelData;
                    if (mouse.button === Qt.LeftButton) { win.openPlace(d); return; }
                    const p = mapToItem(null, mouse.x, mouse.y);
                    const drive = d.device !== undefined;
                    menu.popup(p.x, p.y, [
                        { icon: "open_in_new", text: drive && !d.mounted ? "Mount and open" : "Open", action: () => win.openPlace(d) },
                        !drive || d.mounted ? { icon: "terminal", text: "Open terminal here", action: () => win.terminalHere(d.path) } : null,
                        drive && d.mounted ? { icon: "eject", text: d.removable ? "Eject" : "Unmount", action: () => win.unmount(d) } : null,
                        d.pinned ? { icon: "keep_off", text: "Unpin", action: () => win.unpin(d.path) } : null,
                        d.path === win.trashDir ? { icon: "delete_sweep", text: "Empty Trash", danger: true, action: () => win.emptyTrash() } : null
                    ]);
                }
            }
          }
        }

        component HeaderCell: Item {
            id: hc
            property string label
            property string key
            property bool alignRight: false
            readonly property bool on: Config.files.sortBy === key
            implicitHeight: 30
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: hc.alignRight ? parent.right : undefined
                spacing: 4
                Text {
                    text: hc.label
                    color: hc.on ? Theme.accent : Theme.fg2
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: hc.on
                    anchors.verticalCenter: parent.verticalCenter
                    text: Config.files.sortReversed ? "arrow_upward" : "arrow_downward"
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.fontSize - 1
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (hc.on) Config.files.sortReversed = !Config.files.sortReversed;
                    else { Config.files.sortBy = hc.key; Config.files.sortReversed = false; }
                }
            }
        }

    }
}
