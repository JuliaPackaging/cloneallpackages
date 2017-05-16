using GitHub

auth = authenticate(ENV["GITHUB_AUTH"])
branch_name = "ci_url"

for path in readdir(".")
    if !isdir(path)
        continue
    end

    r = nothing
    try
        r = LibGit2.GitRepo(path)
    except
        println("Trouble with $path")
        continue
    end

    name = LibGit2.url(LibGit2.get(LibGit2.GitRemote, r, "origin"))
    name = split(name, "github.com/")[2]
    if name[end-3:end] == ".git"
        name = name[1:end-4]
    end

    rep = nothing
    try
        rep = repo("staticfloat/" * basename(name); auth=auth)
    except
        warn("Haven't forked $name!")
        continue
    end
        
    # Check to make sure this repository has a branch of that name
    b = nothing
    try
        b = branch(rep, branch_name; auth=auth)
    end
    if b == nothing
        println("No $branch_name branch in $(name)!")
        continue
    end
    println("Opening PR on $name")

    params = Dict(
       :title => "Update CI URLs to point to new caching infrastructure",
       :head => "staticfloat:$(branch_name)",
       :base => "master",
       :body => "Hello there!\nThis is an automated pull request submitted by `@staticfloat` to help package authors transition their Julia installation CI setups to the new binary provider URL.  Please take a look at this PR, and if there is a problem or it doesn't download correctly when CI runs, feel free to ping `@staticfloat`",
       :maintainer_can_modify => true
    )
    try
        pr = PullRequest(GitHub.gh_post_json("/repos/$(name)/pulls"; params=params, auth=auth))
    end
end
