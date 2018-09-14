---
date: "2015-12-18"
title: Using Git as SVN client
---

Using Git as SVN client is quite easy, since the functionality has been built-in already, named the "git-svn" bridge. It boils down to an additional Git command which can be used in the form `git svn <command>`.

<!--more-->

## Working with `git-svn`

### Checkout a. k. a. Clone

Assuming you have an SVN repo at http://svn.example.com/my/repo with all standard paths:

* http://svn.example.com/my/repo/trunk - Trunk
* http://svn.example.com/my/repo/branches - SVN Branches
* http://svn.example.com/my/repo/tags - SVN Tags

Then you can easily clone the full SVN repo with all its history by running:

	git svn clone --stdlayout <url>

This process can take some time since Git clones all history to keep it in the local working copy. In case the history is quite large and you do not need all of it, you can limit the checkout to the most recent revisions using the parameter `--revisions (-r)`.

Afterwards you have a local Git repo like usual, you are in the master branch and you can apply any local workflow you are used to - except for `push` and `pull`, I will outline their differences below.

### SVN Update & Commit

Instead of `fetch/merge`, `pull` and `push`, `git-svn` uses the two commands `svn rebase` and `svn dcommit`. Assuming you use the master branch to synchronize your work with the SVN repo (after the checkout above the SVN remotes should already be configured correctly), a usual workflow may look like this:

        # Starting situation
        # You are in branch "dev" with newer changes than in "master"

        # SVN UPDATE == GIT SVN REBASE
        # First, switch to master branch, fetch an SVN update and rebase the "dev" branch
        git checkout master
        git svn rebase
        git rebase master dev

        # SVN COMMIT == GIT SVN DCOMMIT
        # Now you are back in the "dev" branch (rebase switches the branch automatically)
        # which is up-to-date with the most recent SVN changes.
        # Now, simply merge the local changes into master, then commit them into the SVN
        # repo using "dcommit"
        git checkout master
        git merge dev
        git svn dcommit

Important: Using `git svn rebase` in master only pulls changes from SVN trunk, so if there are any new tags or branches in the SVN repo, you will not (yet) see them in you local Git repo. How to use SVN branches and tags is shown below.

### Working with SVN branches

In case you want (or need) to work with SVN branches in your local Git repo, this can be accomplished quite easily. The workflow is similar to above, you only need to fetch the relevant branches from your SVN remote explicitly from the SVN repo.

        # Synchronize all SVN branches and tags with the local Git repo
        git checkout master
        git svn fetch --fetch-all

        # Locally check out the SVN branch as Git branch and work in it
        git checkout -b <new-git-branch-name> <remotes/svn-branch-name>
        vi <file>
        git add <file>
        git commit -m "Commit message"

        # Fetch SVN updates if any (otherwise commit may fail)
        git svn rebase

        # Commit all changes from local Git branch to remote SVN repository branch
        # (dcommit stands for "delta commit", so the SVN repo will reflect all
        # commits as you see them in your local Git branch - so it may be a good
        # idea to cleanup your non-published history with `git rebase -i` before
        # committing).
        git svn dcommit

You can use all Git magic, branches, merges etc. here as usual.

### Merges between Trunk and Branch

If you want to merge commits or fixes between SVN branches, you can use `git cherry-pick` which is a (tremendously) useful tool. Assuming you have a master branch (corresponding to SVN trunk) and another SVN branch locally, then this can be done git-natively:

        # Checkout target branch (using the branch name of the local git repo, which may
        # deviate from the branch name in the remote SVN repo)
        git checkout <git-branch-name>
        git cherry-pick -x <hash>

`<hash>` refers to an arbitrary commit from the local Git repo, e. g. a specific fix from master / trunk.


## Links

* Official docs: [https://git-scm.com/docs/git-svn](https://git-scm.com/docs/git-svn)
* Useful StackOverflow answer: [https://stackoverflow.com/questions/3239759/checkout-remote-branch-using-git-svn](https://stackoverflow.com/questions/3239759/checkout-remote-branch-using-git-svn)


