--- Returns a list of available versions for the tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
--- @param ctx {args: string[]} Context (args = user arguments)
--- @return table[] List of available versions
function PLUGIN:Available(ctx)
    local http = require("http")

    local repo_url = "https://sourceforge.net/projects/gnucobol/rss?path=/"

    local resp, err = http.get({
        url = repo_url,
    })

    if err ~= nil then
        error("Failed to fetch versions: " .. err)
    end
    if resp.status_code ~= 200 then
        error("SourceForge returned status " .. resp.status_code .. ": " .. resp.body)
    end

    local result = {}
    local seen = {}


    for path in resp.body:gmatch("<title><!%[CDATA%[(.-)%]%]></title>") do
        local version = path:match("^/gnucobol/[^/]+/gnucobol%-(%d+%.%d+%.%d+)%.tar%.gz$")

        if version and not seen[version] then
            seen[version] = true

            table.insert(result, {
                version = version,
            })
        end
    end

    return result
end
