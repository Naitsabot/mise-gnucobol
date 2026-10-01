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

    -- Optional: Legacy version files this plugin can parse
    -- legacyFilenames = {
    --     ".<TOOL>-version",
    --     ".<TOOL>rc"
    -- }

    systemDependencies = {
        {
            name = "gmp",
            pkgconfig = "gmp",
            packages = {
                pacman = "gmp",
                apt = "libgmp-dev",
                dnf = "gmp-devel",
                brew = "gmp",
            },
        },
        {
            name = "ncurses",
            pkgconfig = "ncurses",
            packages = {
                pacman = "ncurses",
                apt = "libncurses-dev",
                dnf = "ncurses-devel",
                brew = "ncurses",
            },
        },
        {
            name = "berkeley-db",
            packages = {
                pacman = "db",
                apt = "libdb-dev",
                dnf = "libdb-devel",
                brew = "berkeley-db",
            },
        },
        {
            name = "json-c",
            pkgconfig = "json-c",
            packages = {
                pacman = "json-c",
                apt = "libjson-c-dev",
                dnf = "json-c-devel",
                brew = "json-c",
            },
        },
        {
            name = "libxml2",
            pkgconfig = "libxml-2.0",
            packages = {
                pacman = "libxml2",
                apt = "libxml2-dev",
                dnf = "libxml2-devel",
                brew = "libxml2",
            },
        },
    }
}
