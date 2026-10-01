-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    name = "gnucobol",
    version = "1.0.0",
    description = "A mise tool plugin for GnuCOBOL",
    author = "Naitsabot",
    updateUrl = "https://github.com/Naitsabot/mise-gnucobol",
    -- Optional: Minimum mise runtime version required
    minRuntimeVersion = "0.2.0",
    systemDependencies = {
        -- Build tools
        {
            bin = "gcc",
            packages = {
                apt = "build-essential",
                dnf = "gcc",
                pacman = "base-devel",
            },
        },
        {
            bin = "make",
            packages = {
                apt = "build-essential",
                dnf = "make",
                pacman = "base-devel",
            },
        },

        -- Libraries
        {
            pkgconfig = "gmp",
            packages = {
                pacman = "gmp",
                apt = "libgmp-dev",
                dnf = "gmp-devel",
                brew = "gmp",
            },
        },
        {
            pkgconfig = "ncurses",
            packages = {
                pacman = "ncurses",
                apt = "libncurses-dev",
                dnf = "ncurses-devel",
                brew = "ncurses",
            },
        },
        {
            -- Berkeley DB ships no .pc file, so check for the header directly.
            -- Use DB_VERSION_MAJOR so macOS's old BSD db.h (no version macros)
            -- does not count as a match, and look in the Homebrew prefix.
            command = 'I=""; '
                .. "if command -v brew >/dev/null 2>&1; then "
                .. 'P=$(brew --prefix berkeley-db 2>/dev/null); [ -n "$P" ] && I="-I$P/include"; '
                .. "fi; "
                .. "printf '#include <db.h>\\nint main(void) { return DB_VERSION_MAJOR; }\\n' | "
                .. 'cc $I -x c - -c -o /dev/null 2>/dev/null',
            packages = {
                pacman = "db",
                apt = "libdb-dev",
                dnf = "libdb-devel",
                brew = "berkeley-db",
            },
        },
        {
            pkgconfig = "json-c",
            packages = {
                pacman = "json-c",
                apt = "libjson-c-dev",
                dnf = "json-c-devel",
                brew = "json-c",
            },
        },
        {
            pkgconfig = "libxml-2.0",
            packages = {
                pacman = "libxml2",
                apt = "libxml2-dev",
                dnf = "libxml2-devel",
                brew = "libxml2",
            },
        },
    },
}