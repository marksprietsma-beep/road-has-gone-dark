# Keep generated World Templates separate from mutable Playthroughs

**Status:** Accepted (existing design and implementation boundary; recorded 16 October 2026).

A **World Template** is immutable source-world truth, identified by its generation provenance. Each **Playthrough** independently owns its party, time, Player Knowledge, World Deltas and results while referencing stable world entities. Facts generated into the world must not automatically become information the player knows.

## Rationale and alternatives

This separation enables one generated world to support multiple campaigns without cross-contaminating their histories, preserves reproducibility, and prevents gameplay from rewriting the authoritative geography. The simpler alternative—a single mutable generated-world object per save—was rejected because it conflates source facts with campaign choices and complicates reuse, provenance and migration.

## Consequences

New gameplay systems must distinguish immutable world facts from Playthrough-specific knowledge and changes. Recorded outcomes must be associated with stable identities and preserved by existing save/versioning rules; the decision does **not** imply an always-running world simulation or prescribe an event-sourcing implementation.
