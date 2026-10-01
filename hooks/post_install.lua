--- Performs additional setup after installation
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook
--- @param ctx {rootPath: string, runtimeVersion: string, sdkInfo: table} Context

-- GnuCOBOL needs a C toolchain (gcc/clang + make) plus GMP, ncurses and
-- Berkeley DB (or GDBM) development headers to build. json-c and libxml2
-- are required here because configure is invoked with --with-json=json-c
-- and --with-xml2. None of these are installed by this plugin.
--   Debian/Ubuntu: apt install build-essential libgmp-dev libncurses-dev libdb-dev libjson-c-dev libxml2-dev
--   Arch:          pacman -S base-devel gmp ncurses db json-c libxml2
--   macOS:         brew install gmp ncurses berkeley-db json-c libxml2

--- Run a shell command and return true on success.
--- Handles both Lua 5.1 (number) and 5.2+ (boolean) os.execute results.
local function command_ok(cmd)
    local status = os.execute(cmd)
    return status == 0 or status == true
end

--- Quote a string for safe use inside a POSIX shell command.
local function sh_quote(value)
    return "'" .. (value:gsub("'", "'\\''")) .. "'"
end

--- Run a command and return its first integer output, or nil.
local function command_int(cmd)
    local handle = io.popen(cmd)
    if not handle then
        return nil
    end
    local output = handle:read("*a")
    handle:close()
    return tonumber(output:match("%d+"))
end

--- Number of parallel build jobs for the current OS.
local function build_jobs()
    local count
    if RUNTIME.osType == "Linux" then
        count = command_int("nproc 2>/dev/null")
    elseif RUNTIME.osType == "Darwin" then
        count = command_int("sysctl -n hw.ncpu 2>/dev/null")
    end
    return tostring(count or 2)
end

--- Build CFLAGS for configure.
--- Recent GCC (14+) rejects implicit function declarations and
--- incompatible pointer types as errors by default, which breaks
--- GnuCOBOL's older C source. Relax those two warnings, the same fix
--- distro packagers use (e.g. Arch's AUR package).
--- Any existing _FORTIFY_SOURCE define is removed because
--- --enable-hardening sets its own.
local function build_cflags()
    local cflags = os.getenv("CFLAGS") or ""
    cflags = cflags:gsub("%-Wp,%-D_FORTIFY_SOURCE=%d", "")
    cflags = cflags:gsub("%-D_FORTIFY_SOURCE=%d", "")
    cflags = cflags:gsub("^%s+", ""):gsub("%s+$", "")

    local extra = {
        "-O2",
        "-Wno-error=implicit-function-declaration",
        "-Wno-error=incompatible-pointer-types",
    }

    if cflags ~= "" then
        return cflags .. " " .. table.concat(extra, " ")
    end
    return table.concat(extra, " ")
end

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    if RUNTIME.osType == "Windows" then
        error("This plugin builds GnuCOBOL from source and does not support Windows directly. Use WSL, or a Linux/macOS host.")
    end

    -- Mise extracts the tarball and strips the top-level directory.
    -- Check that the configure script is present.
    local configure = path .. "/configure"
    if not command_ok("test -f " .. sh_quote(configure)) then
        error("Could not find configure script in " .. path .. ". The source may not have been extracted correctly.")
    end

    -- Configure the build environment.
    -- Missing libraries (GMP, ncurses, Berkeley DB, json-c, libxml2) are
    -- detected by configure itself, which reports which one is missing.
    local configure_cmd = table.concat({
        "cd " .. sh_quote(path),
        "&&",
        "CC=" .. sh_quote("gcc -std=gnu17"),
        "CFLAGS=" .. sh_quote(build_cflags()),
        "./configure",
        "--prefix=" .. sh_quote(path),
        "--infodir=" .. sh_quote(path .. "/share/info"),
        "--enable-hardening",
        "--enable-static=no",
        "--with-db",
        "--with-json=json-c",
        "--with-xml2",
    }, " ")

    if not command_ok(configure_cmd) then
        error(
            "Failed to configure GnuCOBOL. Check the configure output above; "
                .. "it names the missing library. Required: GMP, ncurses, "
                .. "Berkeley DB, json-c, libxml2 (development packages)."
        )
    end

    -- Build
    local build_cmd = string.format("cd %s && make -j%s", sh_quote(path), build_jobs())
    if not command_ok(build_cmd) then
        error("Failed to build GnuCOBOL.")
    end

    -- Install
    local install_cmd = string.format("cd %s && make install", sh_quote(path))
    if not command_ok(install_cmd) then
        error("Failed to install GnuCOBOL.")
    end
end