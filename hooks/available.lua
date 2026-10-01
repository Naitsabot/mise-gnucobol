--- Returns a list of available versions for the GnuCobol from gnu.org
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
--- @param ctx {args: string[]} Context (args = user arguments)
--- @return table[] List of available versions
function PLUGIN:Available(ctx)
    local http = require("http")

    -- GNU Savannah distributes GnuCOBOL source tarballs from the GNU FTP mirror.
    local resp, err = http.get({
        url = "https://ftp.gnu.org/gnu/gnucobol/",
    })

    if err ~= nil then
        error("Failed to fetch versions: " .. err)
    end
    if resp.status_code ~= 200 then
        error("ftp.gnu.org returned status " .. resp.status_code .. ": " .. resp.body)
    end

    local result = {}
    local seen = {}

    -- Rows look like: <a href="gnucobol-3.2.tar.gz">gnucobol-3.2.tar.gz</a>
    -- Anchoring the pattern on the literal ".tar.gz" (not ".tar.gz.sig") keeps signature files out of the result.
    for version in resp.body:gmatch('href="gnucobol%-([%d%.]+)%.tar%.gz"') do
        if not seen[version] then
            seen[version] = true
            table.insert(result, { 
                version = version 
            })
        end
    end

    table.sort(result, function(a, b)
        local function parts(v)
            local p = {}
            for n in v:gmatch("%d+") do
                p[#p + 1] = tonumber(n)
            end
            return p
        end

        local pa, pb = parts(a.version), parts(b.version)

        for i = 1, math.max(#pa, #pb) do
            local na = pa[i] or 0
            local nb = pb[i] or 0

            if na ~= nb then
                return na > nb
            end
        end

        return false
    end)

    return result
end
