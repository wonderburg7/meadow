# check-loop P-1 — make the check format enforceable (delivered 3 Sep 2026)

Status: archived | Owner: Dave / Claude Code | Next: None — slice delivered | Dependency: none | Verified: 2026-09-03

Delivered on branch `claude/P-1`. `tools/check_docs.py` gained `check_checks()`,
which reads `checks/ready.md` and `checks/blocked.md` and fails on an entry
heading without a `C-<n> -- ` id, an entry with no `PASS:` line, an `Owner:`
line naming no plan or a plan that does not exist, or an id used twice across
the two files. Both files' contract paragraphs now say the format is enforced.
One deliberate exception: a `checks/blocked.md` entry may write `Owner: none`
when its owning plan has closed, since its `Blocked by:` line already says what
would give it a new one — C-6 is the live case.

The specification as it stood in `plans/now/check-loop.md`:

## P-1 — make the check format enforceable

**What changed already (3 Sep, this pass).** `checks/ready.md` was rewritten
so every entry has a stable id (`C-1`, `C-2`, …), one action, one **PASS:**
line and a pointer to the slice that owns it. That is what makes a reply
like "C-4 pass, C-7 fails: <what I saw>" unambiguous; this pass had to
interpret prose replies, and got at least one item's meaning only from
context.

**Fix.** Add a `check_checks()` function to `tools/check_docs.py`, in the
style of `check_next_steps()`, that reads `checks/ready.md` and fails if:

- a `### ` entry heading does not start with an id matching `^C-\d+ -- `;
- an entry has no line beginning `PASS:`;
- an entry has no line beginning `Owner:` naming a plan file that exists
  (reuse the existing Markdown-link/path resolution);
- two entries share an id.

Then add the same three lines to `checks/blocked.md`'s contract, and make
the checker skip the file's header block (everything before the first
`### `).

**Acceptance.** `tools/verify.ps1` fails with a readable message when an
entry is added without an id or a PASS line, and passes on the file as this
pass leaves it. No behaviour outside the checker changes.

**Check:** `tools/verify.ps1`, including a deliberate break and repair.

**Files:** `tools/check_docs.py`, `checks/ready.md`, `checks/blocked.md`.

**Reasoning level:** low. A self-contained checker in an established style.

**Next after:** P-3.
