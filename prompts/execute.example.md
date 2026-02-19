Study the following files in order to understand the project:

1. **[README.md](README.md)** - Project overview, features, and configuration
2. **[DEVELOPERS.md](DEVELOPERS.md)** - Build setup, development workflow, and testing
3. **[docs/README.md](docs/README.md)** - Documentation index and navigation

Next, study [the plan](.ralph/plans/EXECUTION_PLAN.md).  The plan describes the implementation steps for the current [spec doc](.ralph/plans/SPECIFICATION.md).  Study both of these files.   This will get you up to speed on where we are, what we are working on and what's left to do.

Some of the work may have been completed in previous sessions.  Audit the code against the spec and the plan to determine what work is left.

If there is no work left to do on this plan, then check if the spec has been completely converted to a document (or set of documents) in the `docs/` folder describing the new state of this code.  If that hasn't been done, then doing so is your next task.

If the plan is truly finished, all changes are documented and there is nothing left to do on this plan, move both the `.ralph/plans/SPECIFICATION.md` and the `.ralph/plans/EXECUTION_PLAN.md` files to the `.ralph/plans/archive/` folder, then report back to the user that there's nothing left to do and await further instructions.

Assuming there still is work left to do to implement this spec, then do the most important thing to move the project forward.  Pick the one most important next task and do it.  You may use up to 10 subagents in any way you see fit.

If you find yourself blocked, try to unblock yourself.  If you cannot unblock yourself, then update [the plan](.ralph/plans/EXECUTION_PLAN.md) to clearly state what the blockers are.  Then, you MUST move BOTH the plan and the spec to the `.ralph/plans/blocked/` folder.  **THAT STEP IS CRITICAL**!  You MUST move both docs if you are blocked!  You should always have beads issues for all your tasks, so mark the related beads issues as blocked as well.

**CRITICAL** Remember to keep the planning docs and beads up to date as you work on the task.

Remember to maintain good documentation quality.  All new features and changes to functionality need to be well documented, in the `docs/` directory.  Follow the existing documentation structure.

Remember to maintain high test coverage.  All new features will need tests.  Bug fixes need tests as well.

That is your workflow. Do all these things for the one task you choose.  Only complete these things for one task, then report back on the status and await further instructions.  

