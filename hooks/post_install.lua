--- Performs additional setup after installation
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook
--- @param ctx {rootPath: string, runtimeVersion: string, sdkInfo: table} Context
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    
    if RUNTIME.osType == "Windows" then
        error("This plugin builds GnuCOBOL from source and does not support Windows directly. Use WSL, or a Linux/macOS host.")
    end
    
    -- Mise extracts the tarball and strips the top-level directory
    -- Test if configure script in path
    local configure = path .. "/configure"
    local status = os.execute(string.format("test -f '%s'", configure))
    if status ~= 0 and status ~= true then
        error("Could not find configure script in " .. path .. ". The source may not have been extracted correctly.")
    end


    local required_headers = {
        "gmp.h",
        "ncurses.h",
        "db.h",
    }

    for _, header in ipairs(required_headers) do
        local cmd = string.format(
            "printf '#include <%s>\\nint main(void) { return 0; }\\n' | " ..
            "gcc -std=gnu17 -O2 -D_FORTIFY_SOURCE=2 -x c - -c -o /dev/null",
            header
        )

        local status = os.execute(cmd)

        if status ~= 0 and status ~= true then
            error("Required development header '" .. header .. "' could not be compiled.")
        end
    end

    -- GnuCOBOL needs a C toolchain (gcc/clang + make) plus GMP, ncurses and
    -- Berkeley DB (or GDBM) development headers to build. json-c and libxml2
    -- are optional (auto-detected, enable JSON/XML support in COBOL
    -- programs). (Not installed by this tool plugin).
    --   Debian/Ubuntu: apt install build-essential libgmp-dev libncurses-dev libdb-dev
    --   Arch:          pacman -S base-devel gmp ncurses db
    --   macOS:         brew install gmp ncurses berkeley-db

    -- Recent GCC (14+) rejects implicit function declarations and
    -- incompatible pointer types as errors by default, which breaks
    -- GnuCOBOL's older C source. Pin the C standard and relax those two
    -- warnings, the same fix distro packagers use (e.g. Arch's AUR package).
    local cflags = os.getenv("CFLAGS") or ""
    cflags = cflags:gsub("%-Wp,-D_FORTIFY_SOURCE=3", "")
    cflags = cflags:gsub("%-Wp,-D_FORTIFY_SOURCE=1", "")
    cflags = cflags:gsub("%-D_FORTIFY_SOURCE=3", "")
    cflags = cflags:gsub("%-D_FORTIFY_SOURCE=1", "")
    cflags = cflags
    .. "-O2"
    .. " -D_FORTIFY_SOURCE=2"
    .. " -Wno-error=implicit-function-declaration"
    .. " -Wno-error=incompatible-pointer-types"

    -- Configure the build environment
    local configure_cmd = string.format(
        "cd '%s' && " ..
        "CC='gcc -std=gnu17' " ..
        "CFLAGS='%s' " ..
        "./configure " ..
        "--prefix='%s' " ..
        "--infodir='%s/share/info' " ..
        "--enable-hardening " ..
        "--enable-static=no " ..
        "--with-db " ..
        "--with-json=json-c " ..
        "--with-xml2",
        path,
        cflags,
        path,
        path
    )

    status = os.execute(configure_cmd)
    if status ~= 0 and status ~= true then
        error("Failed to configure GnuCOBOL build environment.")
    end

    -- Build

    local jobs = "2"

    if RUNTIME.osType == "Linux" then
        local handle = io.popen("nproc 2>/dev/null")
        if handle then
            local output = handle:read("*a")
            handle:close()

            local nproc = tonumber(output:match("%d+"))
            if nproc then
                jobs = tostring(nproc)
            end
        end
    elseif RUNTIME.osType == "Darwin" then
        local handle = io.popen("sysctl -n hw.ncpu 2>/dev/null")
        if handle then
            local output = handle:read("*a")
            handle:close()

            local ncpu = tonumber(output:match("%d+"))
            if ncpu then
                jobs = tostring(ncpu)
            end
        end
    end

    local build_cmd = string.format(
        "cd '%s' && make -j%s",
        path,
        jobs
    )

    status = os.execute(build_cmd)
    if status ~= 0 and status ~= true then
        error("Failed to build GnuCOBOL.")
    end


    -- install

    
    local install_cmd = string.format(
        "cd '%s' && make install",
        path
    )

    status = os.execute(install_cmd)
    if status ~= 0 and status ~= true then
        error("Failed to install GnuCOBOL.")
    end
end