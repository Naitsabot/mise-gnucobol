--- Returns download information for a specific GnuCobol version
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx {version: string, runtimeVersion: string} Context
--- @return table Version and download information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local url = "https://ftp.gnu.org/gnu/gnucobol/gnucobol-" .. version .. ".tar.gz"

    return {
        version = version,
        url = url,
        note = "Downloading GnuCOBOL" .. version,
        addition = {
            name = "signature",
            url = "https://ftp.gnu.org/gnu/gnucobol/$pkgname-$pkgver.tar.xz.sig"
        }
    }
end