function translate_status_url(base, arch)
    # Translate status.julialang.org queries to S3 queries
    if base == "stable"
        if arch == "win64"
            return "https://julialang-s3.julialang.org/bin/winnt/x64/0.5/julia-0.5-latest-win64.exe"
        else
            # arch == "win32"
            return "https://julialang-s3.julialang.org/bin/winnt/x86/0.5/julia-0.5-latest-win32.exe"
        end
    else
        # base == "download"
        if arch == "win64"
            return "https://julialangnightlies-s3.julialang.org/bin/winnt/x64/julia-latest-win64.exe"
        else
            # arch == "win32"
            return "https://julialangnightlies-s3.julialang.org/bin/winnt/x86/julia-latest-win32.exe"
        end
    end
end



function build_julia_url(bucket, uri)
    # We're aliasing the "julianightlies" bucket to the new "julialangnightlies" name
    if bucket == "julianightlies"
        bucket = "julialangnightlies"
    end

    return "https://$(bucket)-s3.julialang.org/$(uri)"
end

# Magic incantation to get TLS 1.2 on Powershell
const ps_tls = "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12"

function translate_path(appveyor_path)
    if isfile(appveyor_path)
        lines = readlines(appveyor_path)

        # First, subvert JULIAVERSION
        JULIAVERSION_LINES=0
        for idx in 1:length(lines)
            # First, search for JULIAVERSION definition
            m = match(r"(\s*-?\s+)JULIA[^ )]+:\s+\"(.*?)/(.*)\"", lines[idx])

            if m != nothing
                if m.captures[2] in ["stable", "download"] && m.captures[3] in ["win32", "win64"]
                    juliaurl = translate_status_url(m.captures[2], m.captures[3])
                else
                    juliaurl = build_julia_url(m.captures[2], m.captures[3])
                end
                JULIAVERSION_LINES += 1
                lines[idx] = "$(m.captures[1])JULIA_URL: \"$(juliaurl)\"\n"
            end
        end

        # Next, replace usage of JULIAVERSION
        ENV_LINES=0
        for idx in 1:length(lines)
            m = match(r"\".*\"\s*\+\s*\$env:JULIA[^ )]+", lines[idx])
            if m != nothing
                ENV_LINES += 1
                pre = lines[idx][1:m.offset-1]
                post = lines[idx][m.offset+length(m.match):end]
                # Eliminate surrounding "$()" if it exists
                if pre[end-1:end] == "\$(" && post[1] == ')'
                    pre = pre[1:end-2]
                    post = post[2:end]
                end
                if !ismatch(r".*s3\.amazonaws\.com.*", m.match) && !ismatch(r".*status\.julialang\.org.*", m.match)
                    warn("$(appveyor_path) has a weird match! $(m.match)")
                end
                lines[idx] = "$(pre)\$env:JULIA_URL$(post)"
            end
        end

        if (JULIAVERSION_LINES > 0 && ENV_LINES == 0) || (JULIAVERSION_LINES == 0 && ENV_LINES > 0)
            warn("$(appveyor_path) didn't conform to our search pattern properly!")
            return
        end

        # Finally, if we haven't yet, switch over to TLS 1.2 for our web clients
        if all(isempty(search(l, ps_tls)) for l in lines)
            # Find the `install:` line
            install_idx = findfirst([ismatch(r"^install:\s*", l) for l in lines])
            if install_idx == 0
                warn("$(appveyor_path) could not auto-detect post-install: whitespace")
                return
            end

            # Get the spacing for the next line
            cmd_idx = install_idx
            m = nothing
            while m == nothing
                cmd_idx += 1
                if cmd_idx > length(lines)
                    warn("$(appveyor_path) could not auto-detect post-install: whitespace")
                    return
                end
                m = match(r"^\s+-\s*", lines[cmd_idx])
            end

            # Insert our powershell tls line just after `install:`
            insert!(lines, install_idx + 1, "$(m.match)ps: \"$(ps_tls)\"\n")
        end

        println("Writing out $appveyor_path")
        open(appveyor_path, "w") do f
            write(f, join(lines, ""))
        end
    end
end

for path in readdir(".")
    if !isdir(path)
        continue
    end

    translate_path(joinpath(path, "appveyor.yml"))
    translate_path(joinpath(path, ".appveyor.yml"))
end
