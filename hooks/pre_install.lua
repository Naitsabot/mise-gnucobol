--- Returns download information for a specific GnuCobol version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    return {
        version = version,
        url = "https://ftp.gnu.org/gnu/gnucobol/gnucobol-" .. version .. ".tar.gz",
        note = "Downloading GnuCOBOL" .. version,
    }
end