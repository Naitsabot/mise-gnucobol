--- Returns a list of available versions for the GnuCobol from gnu.org
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

    if #result == 0 then
        error("No versions found at " .. index_url .. " - the page layout may have changed")
    end

    return result
end
