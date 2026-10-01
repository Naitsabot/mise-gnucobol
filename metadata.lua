-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    -- Required: Tool name (lowercase, no spaces)
    name = "gnucobol",

    -- Required: Plugin version (not the tool version)
    version = "1.0.0",

    -- Required: Brief description of the tool
    description = "A mise tool plugin for GnuCOBOL",

    -- Required: Plugin author/maintainer
    author = "Naitsabot",

    -- Optional: Repository URL for plugin updates
    updateUrl = "https://github.com/Naitsabot/mise-gnucobol",

    -- Optional: Minimum mise runtime version required
    minRuntimeVersion = "0.2.0",

    -- Each entry must set exactly one check: bin, pkgconfig, sharedlib or command.
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
            command = "printf '#include <db.h>\\nint main(void) { return 0; }\\n' | "
                .. "cc -x c - -c -o /dev/null 2>/dev/null",
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