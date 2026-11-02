# Production environment

Brings the **existing, hand-built** BrainKB production under OpenTofu.
Unlike `../sandbox/`, nothing here creates new infrastructure: every
resource is adopted with an `import` block, and the config describes
production exactly as it runs today.

The first `tofu apply` here must change nothing in AWS. It only records
the existing resources in tofu's state, so later changes can be made as
reviewed code instead of console clicks.

## What's adopted (this slice)

| Resource | ID | Source |
|---|---|---|
| EC2 instance `BrainKB` (`c5.4xlarge`) | `i-02f4d763f21e415f0` | `discovery.md` §EC2 |
| Security group `launch-wizard-25` + all its rules | `sg-00ae856ca219ae663` | `discovery.md` §Security groups |

Safety rails:

- `prevent_destroy = true` on both. Any plan that would delete or
  replace production fails rather than being appliable.
- The instance ignores `ami` / `user_data` drift, so a changed AMI ID
  can never force a replacement.
- No `default_tags` (adding tags would be a change). Tagging comes after
  adoption.

## Not adopted yet (next slices, in order)

1. **FSx for Lustre + its S3 bucket + data-repository association, and
   the FSx SG `sg-09898d5bd183b7f15`.** Blocked on the IDs still marked
   TBD in `discovery.md` §Storage. Run
   `aws fsx describe-file-systems --region us-east-2` and record them
   there first.
2. **The three production ALBs, target groups, listeners, ACM certs and
   Route 53 records** for `beta.`, `usermanagement.`, `mlservice.` and
   `mcp.brainkb.org`. Blocked on `discovery.md` §ALB inventory. Note that
   `decisions.md` §6 plans to *replace* these with one ALB via a DNS
   cutover, so it may make more sense to build the new ALB than to
   adopt the old ones. Decide before writing that slice.
3. **The planned changes**, each as its own PR once adoption has landed:
   tags, IAM role + SSM (`decisions.md` §5), closing SSH:22 and
   tightening app ports to ALB-only (§11), and dropping the co-tenant
   sandbox SG rules after the PR #5 cutover.

## How to run

Credentials: same SSO profile you use for sandbox.

    cd tofu/environments/production
    tofu init -backend-config=backend.hcl
    tofu plan

**Read the plan before going any further.** The only acceptable result
is:

    Plan: 2 to import, 0 to add, 0 to change, 0 to destroy.

If it shows any change (for example an SG rule description or tag that
doesn't match what's in AWS), **do not apply**. Fix `main.tf` to match
what AWS reports, and re-run `plan` until it's clean. The config is a
hand-written description of production, so small mismatches are
expected on the first run. To see the exact values AWS has, run:

    aws ec2 describe-security-groups --group-ids sg-00ae856ca219ae663 --region us-east-2
    aws ec2 describe-instances --instance-ids i-02f4d763f21e415f0 --region us-east-2

Inline SG rules are worth extra care: if a rule doesn't match, tofu
revokes it and adds the corrected one, which briefly drops that port on
production.

When the plan is clean:

    tofu apply

Post the plan output on the PR before applying, as was done for sandbox.

## Known guesses to check on the first plan

- SG rule descriptions are taken from discovery.md's "Purpose" column
  and may not match the real text.
- The extra egress rule on port 8004: its destination isn't recorded;
  `0.0.0.0/0` is assumed.
- Other instance tags besides `Name`: any not listed in `main.tf` would
  show as removed. Add them to `main.tf` if so.
