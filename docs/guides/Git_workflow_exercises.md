### GitHub workflows

To get setup as a PhUSE CS collaborator, see [Contributor_setup.md](http://github.com/phuse-org/phuse-scripts/blob/master/docs/guides/Contributor_Setup.md)

### Objective

Script GitHub workflow exercises for CSS 2016.

### GitHub Roles

[GitHub article on Repository Permission Levels](http://help.github.com/articles/repository-permission-levels-for-an-organization/)

  1. Write-Access Collaborators (int): can create/modify "master" files
  2. Read-Access Collaborators (ext):  can send "pull requests" from their own "forks", for the Write-Access team to assess

#### Setup for the phuse-org/phuse-scripts repository

  * Master branch is always "ready to deploy"
  * Therefore relatively few "Write-Access" members, who can
    * create/modify files directly, and
    * review "pull requests", merge them into the "master"
  * Any GitHub member can 
    * "fork" the phuse-scripts repository
    * create/modify files in their "fork"
    * send a "pull request" back to the original, "base" repo (phuse-org/phuse-scripts)

#### GitHub Exercises

  * Simple scenario: EXT. Collaborator suggests a change to an UNmodified file on "master"
    1. EXT. Collaborator:
      * ... forks the phuse-scripts repository
      * ... [or re-SYNC existing, out-of-sync fork]
      * ... creates/modifies file in your new fork
      * ... creates "pull request" in the fork
        * this redirects you to the source repo (note path in page header)
        * request pull _from_ your fork, _to_ the original repo
        * (demo of discussing and resolving a pull request)
    2. INT. Collaborator:
      * ... receives GitHub notification of "pull request" _(depends on user settings)_
      * ... reviews the pull request
      * ... discusses with ext. collaborator
      * ... approves / rejects
    3. EXT. Collaborator:
      * Option to delete fork
      * or maintain by re-syncing with phuse-org/phuse-scripts, and merging in latest changes
  
  * Substantial change: development of new feature takes some time

    1. EXT. Collaborator:
      * ... Re-syncs often with origin repo, so always working with up-to-date files. [Re-syncing requires command line](https://help.github.com/articles/syncing-a-fork/)
      * ... is responsible for merging in latest changes from phuse-org/phuse-scripts, the "base" repo
      * ... develops a new feature, extensive changes in own fork
      * ... creates "pull request" in the fork
    2. INT. Collaborator:
      * ... receives GitHub notification of "pull request" _(depends on user settings)_
      * ... reviews the pull request
      * ... discusses with contributor
        * (will advise EXT. to re-sync & try again, if it's clear s/he has not first pulled latest changes!)
      * ... approves / rejects
    3. _(delete or maintain, same as Simple scenario)_

  * Contributing without GitHub access
    * Via PhUSE Wiki, email to project leads

### Git workflow tutorials

  * [Atlassian Git Workflows](http://www.atlassian.com/git/tutorials/comparing-workflows)
  * [Learn git on Codecademy](http://www.codecademy.com/learn/learn-git)
