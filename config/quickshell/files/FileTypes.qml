pragma Singleton

import QtQuick
import Quickshell

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
