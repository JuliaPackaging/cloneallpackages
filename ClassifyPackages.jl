#!/usr/bin/env julia
isdir(Pkg.dir("YAML")) || Pkg.add("YAML")

module ClassifyPackages
using YAML

cd(dirname(@__FILE__))
allnames = filter!(p -> isdir(p) && p != ".git" &&
    p != "METADATA", readdir())

type PackageInfo
    name::String
    hastravis::Bool
    travisyml::Dict
    language::String
    usesppa::Bool
    jlminver::VersionNumber
    jlmaxver::VersionNumber # looking just at package require, not
# metadata require, so not a complete indicator of package deprecation
    lastcommit::DateTime
end

pkgs = Array(PackageInfo, length(allnames))

for (i, p) in enumerate(allnames)
    pkgs[i] = PackageInfo(p, false, Dict(), "", false,
        v"0.0", typemax(VersionNumber), now())
    ymlpath = joinpath(p, ".travis.yml")
    if isfile(ymlpath)
        pkgs[i].hastravis = true
        ymlstring = readstring(ymlpath)
        yml = YAML.load(ymlstring)
        pkgs[i].travisyml = yml
        if haskey(yml, "language")
            pkgs[i].language = yml["language"]
        end
        pkgs[i].usesppa = contains(ymlstring, "ppa:staticfloat")
    end
    requirepath = joinpath(p, "REQUIRE")
    if isfile(requirepath)
        reqs = Pkg.Reqs.parse(requirepath)
        if haskey(reqs, "julia")
            juliareq = reqs["julia"]
            if length(juliareq.intervals) == 1
                interval = juliareq.intervals[1]
                pkgs[i].jlminver = interval.lower
                pkgs[i].jlmaxver = interval.upper
            else
                error("complicated julia requirement for $p: $juliareq")
            end
        end
    end
    cd(p) do
        pkgs[i].lastcommit = Dates.unix2datetime(parse(Int,
            readchomp(`git log -1 --format=%ct`)))
    end
end

#=
# interesting notes:
for f in fieldnames(PackageInfo)
    @eval $f = map(p -> p.$f, pkgs)
end
# or language = getfield.(pkgs, [:language])
unique(language) # julia, cpp, ruby, none
name[language .== "ruby"] # only MsgPackRpcServer
name[(language .== "cpp") & ~usesppa] # only SystemImageBuilder
name[(language .== "") & hastravis] # only Cxx
name[(language .== "julia") & usesppa] # BuildExecutable and Playground for julia-deps patchelf

name[~haskey.(travisyml, ["julia"]) & (language .== "julia")]
# 7 packages: 5 with matrices, CauseMap and LLLplus missing julia entries
=#

end # module
