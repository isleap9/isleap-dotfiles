pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// File kinds by extension → Material Symbol, plus size / date formatting
Singleton {
    readonly property var groups: ({
        image: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "heic", "tif", "tiff", "ico", "jxl"],
        video: ["mp4", "mkv", "webm", "avi", "mov", "m4v", "flv", "wmv", "mpg", "mpeg"],
        audio: ["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"],
        archive: ["zip", "tar", "gz", "xz", "zst", "bz2", "7z", "rar", "tgz", "deb", "rpm", "iso", "img"],
        code: ["js", "ts", "qml", "py", "c", "h", "cpp", "hpp", "rs", "go", "java", "kt", "lua", "html", "css",
            "scss", "jsx", "tsx", "vue", "rb", "php", "cs", "swift", "zig", "nix"],
        script: ["sh", "bash", "zsh", "fish"],
        data: ["json", "yaml", "yml", "toml", "xml", "ini", "conf", "cfg", "csv", "sql", "db", "sqlite"],
        doc: ["doc", "docx", "odt", "rtf"],
        sheet: ["xls", "xlsx", "ods"],
        slides: ["ppt", "pptx", "odp"],
        pdf: ["pdf"],
        text: ["txt", "md", "log", "nfo", "org", "rst"],
        font: ["ttf", "otf", "woff", "woff2"],
        exe: ["appimage", "exe", "msi", "bin", "run", "desktop"]
    })
    readonly property var icons: ({
        folder: "folder", image: "image", video: "movie", audio: "music_note", archive: "folder_zip",
        code: "code", script: "terminal", data: "data_object", doc: "article", sheet: "table_chart",
        slides: "slideshow", pdf: "picture_as_pdf", text: "description", font: "font_download",
        exe: "deployed_code", file: "draft"
    })
    // Folders that get their own icon
    readonly property var folderIcons: ({
        Desktop: "desktop_windows", Documents: "folder_open", Downloads: "download", Music: "library_music",
        Pictures: "photo_library", Videos: "video_library", Templates: "file_copy", Public: "folder_shared"
    })

    readonly property var byExt: {
        const map = {};
        for (const kind in groups)
            for (const e of groups[kind]) map[e] = kind;
        return map;
    }

    // ---------- system (icon theme) icons, e.g. Papirus ----------
    // File type from the shared MIME database's file-name patterns, like Dolphin / Nautilus do
    property var globExt: ({})         // "py" → "text/x-python", "tar.gz" → "application/x-compressed-tar"
    property var globName: ({})        // exact names: "makefile" → "text/x-makefile"
    property var genericIcons: ({})    // mime → fallback icon name
    FileView {
        path: "/usr/share/mime/globs2"
        onLoaded: {
            const ext = {}, names = {};
            for (const line of text().split("\n")) {
                if (!line || line[0] === "#") continue;
                const parts = line.split(":");
                if (parts.length < 3) continue;
                const mime = parts[1], pat = parts[2].toLowerCase();
                // Lines are sorted by weight, so the first match wins
                if (/^\*\.[^*?\[]+$/.test(pat)) { const e = pat.slice(2); if (!(e in ext)) ext[e] = mime; }
                else if (!/[*?\[]/.test(pat)) { if (!(pat in names)) names[pat] = mime; }
            }
            globExt = ext;
            globName = names;
        }
    }
    FileView {
        path: "/usr/share/mime/generic-icons"
        onLoaded: {
            const map = {};
            for (const line of text().split("\n")) {
                const i = line.indexOf(":");
                if (i > 0) map[line.slice(0, i)] = line.slice(i + 1).trim();
            }
            genericIcons = map;
        }
    }
    function mime(name) {
        const n = name.toLowerCase();
        if (globName[n]) return globName[n];
        // Longest suffix first: "a.tar.gz" tries "tar.gz" before "gz"
        for (let i = n.indexOf("."); i >= 0; i = n.indexOf(".", i + 1)) {
            const m = globExt[n.slice(i + 1)];
            if (m) return m;
        }
        return "";
    }
    // Special folders by name (the theme decides which of these it has)
    readonly property var folderNames: ({
        Desktop: "user-desktop", Documents: "folder-documents", Downloads: "folder-download",
        Music: "folder-music", Pictures: "folder-pictures", Videos: "folder-videos",
        Templates: "folder-templates", Public: "folder-publicshare", Trash: "user-trash"
    })
    // Icon names to try, best first
    function systemIconNames(name, isDir, path) {
        if (isDir) {
            if (path === Quickshell.env("HOME")) return ["user-home", "folder"];
            const low = name.toLowerCase().replace(/[ _]+/g, "-");
            return [folderNames[name] ?? "", "folder-" + low, "folder"].filter(n => n);
        }
        const m = mime(name);
        const k = kind(name, false);
        const byKind = { image: "image-x-generic", video: "video-x-generic", audio: "audio-x-generic",
            archive: "package-x-generic", code: "text-x-script", script: "application-x-shellscript",
            data: "text-x-generic", doc: "x-office-document", sheet: "x-office-spreadsheet",
            slides: "x-office-presentation", pdf: "application-pdf", text: "text-x-generic",
            font: "font-x-generic", exe: "application-x-executable" }[k];
        return [m ? m.replace("/", "-") : "", m ? genericIcons[m] ?? "" : "", byKind ?? "", "text-x-generic", "unknown"]
            .filter(n => n);
    }
    function systemIcon(name, isDir, path) {
        // Folders come straight from Papirus-Accent (recolored to the theme), with a version so
        // a theme change shows the new color immediately instead of a cached icon
        if (isDir) {
            for (const n of systemIconNames(name, true, path))
                if (Theme.folderIcons[n])
                    return "file://" + Theme.folderIconDir + "/64x64/places/" + n + ".svg?v=" + Theme.folderIconVersion;
        }
        for (const n of systemIconNames(name, isDir, path)) {
            const p = Quickshell.iconPath(n, true);
            if (p) return p;
        }
        return Quickshell.iconPath("unknown");
    }

    function ext(name) {
        const i = name.lastIndexOf(".");
        return i > 0 ? name.slice(i + 1).toLowerCase() : "";
    }
    function kind(name, isDir) {
        return isDir ? "folder" : byExt[ext(name)] ?? "file";
    }
    function icon(name, isDir) {
        if (isDir) return folderIcons[name] ?? "folder";
        return icons[kind(name, false)];
    }

    // file:// URL for a path (encodes spaces, #, ? …)
    function url(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function size(bytes) {
        if (bytes < 1024) return bytes + " B";
        const units = ["KB", "MB", "GB", "TB"];
        let v = bytes, i = -1;
        do { v /= 1024; i++; } while (v >= 1024 && i < units.length - 1);
        return (v < 10 ? v.toFixed(1) : Math.round(v)) + " " + units[i];
    }
    function date(d) {
        if (!d) return "";
        const t = new Date(d);
        const now = new Date();
        const day = new Date(t.getFullYear(), t.getMonth(), t.getDate());
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const diff = Math.round((today - day) / 86400000);
        if (diff === 0) return "Today, " + Qt.formatTime(t, "HH:mm");
        if (diff === 1) return "Yesterday, " + Qt.formatTime(t, "HH:mm");
        if (t.getFullYear() === now.getFullYear()) return Qt.formatDate(t, "d MMM");
        return Qt.formatDate(t, "d MMM yyyy");
    }
}
