--- Builds GnuCOBOL from source and installs it into the mise install directory.
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook
---
--- Build requirements (not installed by this plugin; see metadata.lua):
--- a C toolchain (gcc/clang + make) plus GMP, ncurses, Berkeley DB, json-c
--- and libxml2 development packages.
---   Debian/Ubuntu: apt install build-essential libgmp-dev libncurses-dev libdb-dev libjson-c-dev libxml2-dev
---   Arch:          pacman -S base-devel gmp ncurses db json-c libxml2
---   macOS:         brew install gmp ncurses berkeley-db json-c libxml2

-- Strips bytes that are not valid UTF-8. mise discards the rest of a task's
-- output when it meets such bytes, which hides the real configure error.
local SANITIZE = "LC_ALL=C tr -cd '[:print:]\\n\\t'"

--- Lowercased OS name. The vfox runtime reports "darwin", "linux" and
--- "windows" in lowercase.
local function os_type()
    return (RUNTIME.osType or ""):lower()
end

--- Run a shell command and return true on success.
--- Handles both Lua 5.1 (number) and 5.2+ (boolean) os.execute results.
local function command_ok(cmd)
    local status = os.execute(cmd)
    return status == 0 or status == true
end

--- Run a shell command and raise `message` if it fails.
local function run(cmd, message)
    if not command_ok(cmd) then
        error(message)
    end
end

--- Run a shell command and return its stdout ("" on failure to start).
local function read_output(cmd)
    local handle = io.popen(cmd)
    if not handle then
        return ""
    end
    local output = handle:read("*a")
    handle:close()
    return output
end

--- Quote a string for safe use inside a POSIX shell command.
local function sh_quote(value)
    return "'" .. (value:gsub("'", "'\\''")) .. "'"
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Number of parallel build jobs for the current OS.
local function build_jobs()
    local cmd
    if os_type() == "linux" then
        cmd = "nproc"
    elseif os_type() == "darwin" then
        cmd = "sysctl -n hw.ncpu"
    end
    local count = cmd and tonumber(read_output(cmd .. " 2>/dev/null"):match("%d+"))
    return tostring(count or 2)
end

--- Return the Homebrew prefix of a formula, or nil if it is not installed.
--- Falls back to the standard Homebrew locations in case `brew` is not on
--- the PATH of the hook's shell.
local function brew_prefix(formula)
    local candidates = {}

    local prefix = trim(read_output("brew --prefix " .. sh_quote(formula) .. " 2>/dev/null"))
    if prefix ~= "" then
        table.insert(candidates, prefix)
    end
    table.insert(candidates, "/opt/homebrew/opt/" .. formula) -- Apple Silicon
    table.insert(candidates, "/usr/local/opt/" .. formula) -- Intel

    for _, candidate in ipairs(candidates) do
        if command_ok("test -d " .. sh_quote(candidate .. "/include")) then
            return candidate
        end
    end
    return nil
end

--- CPPFLAGS and LDFLAGS for configure.
--- macOS ships an old BSD db.h (Berkeley DB 1.85) in the SDK. It has no
--- version macros, so configure finds it and then cannot extract a version.
--- The Homebrew include path must come first to shadow it. Homebrew
--- libraries are also outside the default search path on Apple Silicon.
local function build_cpp_ld_flags()
    local cppflags = os.getenv("CPPFLAGS") or ""
    local ldflags = os.getenv("LDFLAGS") or ""

    if os_type() == "darwin" then
        local cpp, ld = {}, {}
        for _, formula in ipairs({ "berkeley-db", "gmp", "json-c" }) do
            local prefix = brew_prefix(formula)
            if prefix then
                table.insert(cpp, "-I" .. prefix .. "/include")
                table.insert(ld, "-L" .. prefix .. "/lib")
            end
        end
        if #cpp > 0 then
            cppflags = table.concat(cpp, " ") .. " " .. cppflags
            ldflags = table.concat(ld, " ") .. " " .. ldflags
        end
    end

    return trim(cppflags), trim(ldflags)
end

--- CFLAGS for configure.
--- GCC 14+ rejects implicit function declarations and incompatible pointer
--- types as errors by default, which breaks GnuCOBOL's older C source. Relax
--- those two diagnostics, as distro packagers do (e.g. Arch's AUR package).
--- Any existing _FORTIFY_SOURCE define is removed because
--- --enable-hardening sets its own.
local function build_cflags()
    local cflags = os.getenv("CFLAGS") or ""
    cflags = cflags:gsub("%-Wp,%-D_FORTIFY_SOURCE=%d", "")
    cflags = cflags:gsub("%-D_FORTIFY_SOURCE=%d", "")

    local extra = {
        "-O2",
        "-Wno-error=implicit-function-declaration",
        "-Wno-error=incompatible-pointer-types",
    }
    return trim(cflags .. " " .. table.concat(extra, " "))
end

--- @param ctx {rootPath: string, runtimeVersion: string, sdkInfo: table} Context
function PLUGIN:PostInstall(ctx)
    local path = ctx.sdkInfo[PLUGIN.name].path

    if os_type() == "windows" then
        error("This plugin builds GnuCOBOL from source and does not support Windows directly. Use WSL, or a Linux/macOS host.")
    end

    -- mise extracts the tarball and strips the top-level directory.
    run(
        "test -f " .. sh_quote(path .. "/configure"),
        "Could not find configure script in " .. path .. ". The source may not have been extracted correctly."
    )

    -- The macOS SDK's db.h cannot be used by GnuCOBOL (see build_cpp_ld_flags).
    if os_type() == "darwin" and not brew_prefix("berkeley-db") then
        error("Homebrew's Berkeley DB was not found. Run `brew install berkeley-db` and retry.")
    end

    -- Build out of tree. The install prefix is the source directory, so an
    -- in-tree build makes `make install` copy generated files (e.g.
    -- bin/cob-config) onto themselves, which GNU install rejects.
    local builddir = path .. "/mise-build"
    run("mkdir -p " .. sh_quote(builddir), "Could not create build directory " .. builddir)

    -- Configure. Missing libraries are detected by configure itself, which
    -- names the one that is missing. Output goes to a file and is printed
    -- sanitized, keeping configure's exit status.
    local cppflags, ldflags = build_cpp_ld_flags()
    local configure_cmd = table.concat({
        "CC=" .. sh_quote("gcc -std=gnu17"),
        "CFLAGS=" .. sh_quote(build_cflags()),
        "CPPFLAGS=" .. sh_quote(cppflags),
        "LDFLAGS=" .. sh_quote(ldflags),
        "../configure",
        "--prefix=" .. sh_quote(path),
        "--infodir=" .. sh_quote(path .. "/share/info"),
        "--enable-hardening",
        "--enable-static=no",
        "--with-db",
        "--with-json=json-c",
        "--with-xml2",
    }, " ")

    local logfile = sh_quote(builddir .. "/configure.out")
    run(
        table.concat({
            "cd " .. sh_quote(builddir) .. ";",
            "(" .. configure_cmd .. ") > " .. logfile .. " 2>&1;",
            "rc=$?;",
            SANITIZE .. " < " .. logfile .. ";",
            "exit $rc",
        }, " "),
        "Failed to configure GnuCOBOL. See the configure output above. Required "
            .. "libraries: GMP, ncurses, Berkeley DB, json-c, libxml2 (development packages)."
    )

    -- Build and install.
    run(string.format("cd %s && make -j%s", sh_quote(builddir), build_jobs()), "Failed to build GnuCOBOL.")
    run(string.format("cd %s && make install", sh_quote(builddir)), "Failed to install GnuCOBOL.")

    command_ok("rm -rf " .. sh_quote(builddir))
end