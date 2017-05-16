# This file pushes local changes to the branch name of your choice
branch_name = "ci_url"

for path in reverse(readdir("."))
    if !isdir(path)
        continue
    end

    r = nothing
    try
        r = LibGit2.GitRepo(path)
    end
    if !LibGit2.isdirty(r)
        println("Not Dirty: $path")
        continue
    end
    println("Pushing: $path")
    LibGit2.set_remote_url(r, "git@github.com:staticfloat/$(path).jl"; remote="github")
    LibGit2.branch!(r, branch_name)
    LibGit2.add!(r, ".")
    LibGit2.commit(r, "Update CI URLs to point to new caching infrastructure")
    try
        LibGit2.push(r; remote="github", refspecs=["refs/heads/$(branch_name)"], force=true)
    except
        warn("Failed to push $path")
        continue
    end
end
