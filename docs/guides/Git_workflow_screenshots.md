#### Git workflow exercises

These are selected screenshots of the [Git workflow exercises](https://github.com/phuse-org/phuse-scripts/blob/master/docs/guides/Git_workflow_exercises.md)

##### Simple scenario

**EXT. Collaborator forks the phuse-scripts repository:**

![simple_01](./images/Git_workflow_exercises_simple_01.png)

**which creates their own forked repository from the original phuse-org/phuse-scripts repo:**

![simple_02](./images/Git_workflow_exercises_simple_02.png)

**EXT. Collaborator then creates/modifies files in own fork:**

![simple_03](./images/Git_workflow_exercises_simple_03.png)

**EXT. Collaborator then creates a new pull request:**

![simple_04](./images/Git_workflow_exercises_simple_04.png)

**which re-directs back to the original base repository, to explain the pull request:**

![simple_05](./images/Git_workflow_exercises_simple_05.png)

**Discussion takes place between INT and EXT collaborators, in the pull request in the original repo**

![simple_06](./images/Git_workflow_exercises_simple_06.png)

**Back in sync, if the INT Collaborator accepts and merges the requested changes**

![simple_07](./images/Git_workflow_exercises_simple_07.png)

##### Substantial change: development of new feature takes some time

**If the INT and EXT Collaborators make conflicting changes:**

  * **the EXT collaborator must merge the latest base repo into his/er own fork.**
  * **GitHub Desktop client makes this easy:**

![substantial_01](./images/Git_workflow_exercises_substantial_01.png)

  * **GitHub highlights the changes, annotating the conflicts in the "cloned" copy of the file.**
  *  **The EXT. collaborators reconciles the conflicts and merges the resulting file into the local clone of their forked repo.**
  *  **GitHub then permits the EXT. collaborator to commit these merged changes into the local clone:**

![substantial_02](./images/Git_workflow_exercises_substantial_02.png)

**The EXT. Collaborator is once again ready to create a new pull request, from the re-synced, modified fork:**

![substantial_03](./images/Git_workflow_exercises_substantial_03.png)
