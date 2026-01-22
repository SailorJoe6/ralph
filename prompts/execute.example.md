Study the following files in order to understand the project:

1. **[README.md](README.md)** - Project overview, features, and configuration
2. **[DEVELOPERS.md](DEVELOPERS.md)** - Build setup, development workflow, and testing
3. **[docs/README.md](docs/README.md)** - Documentation index and navigation

Pay special attention to instructions about using the Make files!

Finally run `bd prime` to understand our beads workflow.

Next, study the [planning index](docs/planning/README.md) and read any other docs in the `docs/planning/` folder.  In that file, you should find [the plan](ralph/plans/EXECUTION_PLAN.md).  The plan describes the implementation steps for the current [spec doc](ralph/plans/SPECIFICATION.md).  Study both of these files.   This will get you up to speed on where we are, what we are working on and what's left to do.

There may be some tickets in beads related to the plan, and you may need to create beads tickets as you implement the plan.  There may be some tickets that are not related to the plan.  Focus on the plan and plan related tickets.

Some of the work may have been completed in previous sessions.  Audit the code against the spec and the plan to deterine what work is left.

If you find a ticket that is not closed in beads, but you find the work for the ticket is all the way done, you should check to ensure proper documentation and tests exist for the finished work, and if everything is perfect you should close that ticket and ensure the plan represents the finished work.

If there is no work left to do on this plan, then check if the spec has been completely converted to a document (or set of documents) in the docs folder describing the new state of this code.  If that hasn't been done, then doing so is your next task.

If the plan is truly finished and there is nothing left to do on this plan, delete both the `ralph/plans/SPECIFICATION.md` and the `ralph/plans/EXECUTION_PLAN.md` files, then report back to the user that there's nothing left to do and await further instructions.

Assuming there still is work left to do to implement this spec, then do the most imporant thing to move the project forward.  Pick the one most important next task and do it.  You may use up to 10 subagents in any way you see fit.

If you find yourself blocked, try to unblock yourself.  If you cannot unblock yourself, then update [the plan](ralph/plans/EXECUTION_PLAN.md) to clearly state what the blockers are.  You should always have beads issues for all your tasks, so mark your beads issues as blocked as well.

Remember to keep the planning docs and beads up to date as you work on the task.

Remember to dogfood code-scout as you work on the task, it's the best way to learn about this codebase.

Remember to maintain good documentation quality.  All new features and changes to functionality need to be well documented, in the `docs/` direcotry.  Follow the existing documentation structure.

Remember to maintain high test coverage.  All new features will need tests.  Bug fixes need tests as well.

Remember to index with code-scout after your any changes or any new code has been written, tested and documented.

That is your workflow. Do all these things for the one task you choose.  Only complete these thigns for one task, then report back on the status and await further instructions.  

