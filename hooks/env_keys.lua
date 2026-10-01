--- Configures environment variables for the installed tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook
--- @param ctx {path: string, runtimeVersion: string, sdkInfo: table} Context
--- @return table[] List of environment variable definitions
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    local env_vars = {
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
        {
            key = "COB_CONFIG_DIR",
            value = mainPath .. "/share/gnucobol/config",
        },
        {
            key = "PKG_CONFIG_PATH",
            value = mainPath .. "/lib/pkgconfig",
        },
    }

    -- cobc dynamically links against libcob, and any COBOL program built with cobc links against it too, so the loader needs to find it.
    if RUNTIME.osType == "Darwin" then
        table.insert(env_vars, {
            key = "DYLD_LIBRARY_PATH",
            value = mainPath .. "/lib",
        })
    else
        table.insert(env_vars, {
            key = "LD_LIBRARY_PATH",
            value = mainPath .. "/lib",
        })
    end

    return env_vars
end