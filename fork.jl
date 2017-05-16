# This file looks at every directory within the given path and forks it to your github account.
# Prepare to have a LOT of repositories.
using GitHub

auth = authenticate(ENV["GITHUB_AUTH"])

for path in readdir(".")
    if !isdir(path)
        continue
    end

    try
        r = LibGit2.GitRepo(path)
        name = LibGit2.url(LibGit2.get(LibGit2.GitRemote, r, "origin"))
        name = split(name, "github.com/")[2]
        if name[end-3:end] == ".git"
            name = name[1:end-4]
        end

        try
            repo("staticfloat/" * basename(name); auth=auth)
            println("Already forked $name")
            continue
        end
        println("Forking $name")
        create_fork(repo(name; auth=auth); auth=auth)
    catch
        warn("Problems in $path")
        continue
    end
end
