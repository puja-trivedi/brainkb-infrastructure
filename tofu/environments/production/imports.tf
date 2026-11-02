# Adopt the existing production resources (IDs from discovery.md).
# Import blocks are safe to leave in place after the first apply —
# once a resource is in state they're a no-op.

import {
  to = aws_instance.app
  id = "i-02f4d763f21e415f0"
}

import {
  to = aws_security_group.app
  id = "sg-00ae856ca219ae663"
}
