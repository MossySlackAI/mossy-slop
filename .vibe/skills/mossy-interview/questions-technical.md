# Technical Interview Questions

Technical-scope question bank for mossy-interview. Simplified from flow-next (technical mode only, no business questions).

Ask **NON-OBVIOUS** questions only. Expect 10-30 questions for typical specs.

## Pre-Question Taxonomy

Before asking ANY question, classify it:

| Category | Who Answers | Action | Examples |
|----------|-------------|--------|----------|
| **Codebase-answerable** | Agent | Investigate via Read/Grep/Glob | "What DB layer exists?" / "Where are API routes defined?" / "What test framework is used?" |
| **User-judgment-required** | User | Ask via `ask_user_question` | "Should we add caching?" / "What's the priority?" / "Which tradeoff to make?" |

**RULE**: If you can answer it with grep, DON'T ask the user.

**Audit trail**: Codebase-resolved items → `## Resolved via Codebase` section with file:line evidence.

---

## Category 1: Scope

**Purpose**: Establish what's in and out of scope, component boundaries.

**Dependency order**: Ask these FIRST - they determine which other questions are relevant.

### Questions

1. **Scope confirmation**
   - "What is the primary objective of this feature/change?"
   - "What specific problem does this solve?"
   - Recommended: Based on spec title/goal - confirm or refine
   - Confidence: [judgment-call]

2. **In/Out of scope**
   - "What is explicitly OUT of scope for this change?"
   - "Are there related features that should be tackled separately?"
   - Recommended: List common adjacent features to exclude
   - Confidence: [your-call]

3. **Component boundaries**
   - "Which existing components will this touch?"
   - "Should this be a new component/module or extend existing ones?"
   - Recommended: Based on grep of similar features
   - Confidence: [high] if codebase has clear patterns

4. **Integration points**
   - "What existing systems/components does this need to integrate with?"
   - "Are there external APIs or services to connect to?"
   - Recommended: Based on grep for API clients, service connections
   - Confidence: [high] if integrations already exist

---

## Category 2: Architecture

**Purpose**: Determine high-level structure, dependencies, and design approach.

**Dependency**: Requires Scope to be established first.

### Questions

1. **Architecture pattern**
   - "What architecture pattern fits this best? (e.g., MVC, microservice, layer pattern)"
   - "Should this follow existing patterns or introduce a new one?"
   - Recommended: Match existing codebase patterns
   - Confidence: [high] if codebase has consistent pattern

2. **Component responsibility**
   - "How should responsibilities be divided among components?"
   - "What are the core classes/modules needed?"
   - Recommended: Based on Single Responsibility Principle
   - Confidence: [judgment-call]

3. **Dependencies**
   - "What new dependencies will this require?"
   - "Are there existing dependencies to leverage?"
   - Recommended: Check package.json, requirements.txt, pom.xml etc.
   - Confidence: [high] if dependency already exists

4. **Parallel work potential**
   - "Can this be split so tasks touch disjoint files? (reduces merge conflicts)"
   - "Which parts can be developed in parallel?"
   - Recommended: Identify independent modules
   - Confidence: [judgment-call]

5. **Task sizing**
   - "Can sequential steps be combined into manageable tasks?"
   - "What's a reasonable size for individual tasks?"
   - Recommended: Avoid over-splitting
   - Confidence: [your-call]

---

## Category 3: Data Models & State

**Purpose**: Determine data structures, persistence, and state management approach.

**Dependency**: Skip if no persistence needed (from Scope questions).

### Questions

1. **Persistence requirement**
   - "Does this feature need persistence?"
   - "What data needs to be stored?"
   - Recommended: Based on feature type
   - Confidence: [high] if similar features exist
   - **If NO**: Skip to state management questions, note: "Skipping persistence questions — no DB needed"

2. **Data structures**
   - "What are the core data structures?"
   - "What fields/properties are needed?"
   - Recommended: Based on requirements
   - Confidence: [judgment-call]

3. **Existing models**
   - "Can existing data models be extended?"
   - "Should new models be created?"
   - Recommended: Check existing models via grep
   - Confidence: [high] if matching models exist

4. **State management**
   - "How should state be managed? (e.g., local state, global store, database)"
   - "What state needs to persist across sessions?"
   - Recommended: Based on feature requirements
   - Confidence: [judgment-call]

5. **Schema migration**
   - "Will this require database schema changes?"
   - "How should migrations be handled?"
   - Recommended: Check existing migration patterns
   - Confidence: [high] if migration patterns exist

---

## Category 4: API Contracts

**Purpose**: Define interfaces, endpoints, and data shapes.

**Dependency**: Only if feature has API surface.

### Questions

1. **API surface needed**
   - "Does this feature require new API endpoints?"
   - "What existing endpoints can be extended?"
   - Recommended: Check existing API structure
   - Confidence: [high] if API patterns exist
   - **If NO**: Skip remaining API questions

2. **Endpoint design**
   - "What are the required endpoints?"
   - "What HTTP methods should they use?"
   - Recommended: RESTful conventions
   - Confidence: [high] if conventions are clear

3. **Request/Response shapes**
   - "What data should requests accept?"
   - "What data should responses return?"
   - Recommended: Match existing patterns
   - Confidence: [judgment-call]

4. **Error handling**
   - "What error responses are needed?"
   - "What status codes should be returned?"
   - Recommended: HTTP status code conventions
   - Confidence: [high]

5. **Versioning**
   - "Should this be versioned?"
   - "How should API versioning be handled?"
   - Recommended: Check existing versioning strategy
   - Confidence: [high] if versioning exists

---

## Category 5: Edge Cases

**Purpose**: Identify failure modes, boundary conditions, and constraints.

**Dependency**: Can be asked anytime after basic scope is clear.

### Questions

1. **Failure modes**
   - "What can go wrong?"
   - "What are the critical failure scenarios?"
   - Recommended: List common failure patterns for this feature type
   - Confidence: [judgment-call]

2. **Input validation**
   - "What input validation is needed?"
   - "What are the edge cases for inputs?"
   - Recommended: Based on data types and constraints
   - Confidence: [high] if similar validation exists

3. **Boundary conditions**
   - "What are the minimum/maximum values?"
   - "What are the limits?"
   - Recommended: Based on requirements
   - Confidence: [your-call]

4. **Error recovery**
   - "How should errors be recovered from?"
   - "What retry logic is needed?"
   - Recommended: Based on existing patterns
   - Confidence: [high] if patterns exist

5. **Constraints**
   - "What technical constraints exist? (memory, storage, etc.)"
   - "Are there external constraints to consider?"
   - Recommended: Based on infrastructure
   - Confidence: [your-call]

---

## Category 6: Performance

**Purpose**: Determine scale expectations and performance requirements.

**Dependency**: Only if performance is a concern (ask after understanding scope).

### Questions

1. **Scale expectations**
   - "What is the expected load/scale?"
   - "How many users/requests expected?"
   - Recommended: Based on similar features
   - Confidence: [your-call]

2. **Latency requirements**
   - "What are the latency requirements?"
   - "Are there real-time constraints?"
   - Recommended: Based on feature type
   - Confidence: [your-call]

3. **Memory constraints**
   - "What are the memory constraints?"
   - "Should caching be used?"
   - Recommended: Based on data size
   - Confidence: [judgment-call]

4. **Caching strategy**
   - "What caching strategy is needed?"
   - "What should be cached and for how long?"
   - Recommended: Based on access patterns
   - Confidence: [judgment-call]

---

## Category 7: Security

**Purpose**: Identify security considerations.

**Dependency**: Only if feature handles sensitive data or has external exposure.

### Questions

1. **Authentication/Authorization**
   - "Does this require authentication?"
   - "What authorization checks are needed?"
   - Recommended: Check existing auth patterns
   - Confidence: [high] if auth patterns exist

2. **Input validation** (if not covered in Edge Cases)
   - "What security validation is needed?"
   - "Are there injection risks to consider?"
   - Recommended: OWASP guidelines
   - Confidence: [high]

3. **Data sensitivity**
   - "Does this handle sensitive data?"
   - "What data protection is needed?"
   - Recommended: Encryption, anonymization
   - Confidence: [high] if similar data exists

4. **Attack vectors**
   - "What are the potential attack vectors?"
   - "How can this be abused?"
   - Recommended: Based on feature type
   - Confidence: [judgment-call]

---

## Category 8: Testing Strategy

**Purpose**: Determine testing approach.

**Dependency**: Can be asked anytime after scope is clear.

### Questions

1. **Unit test focus**
   - "What are the key areas for unit tests?"
   - "What edge cases should unit tests cover?"
   - Recommended: Core logic, edge cases
   - Confidence: [high]

2. **Integration tests**
   - "What integration test scenarios are needed?"
   - "What components need to be tested together?"
   - Recommended: Integration points
   - Confidence: [judgment-call]

3. **E2E tests**
   - "What are the critical E2E paths?"
   - "What user journeys should be tested?"
   - Recommended: User-facing features
   - Confidence: [judgment-call]

4. **Mocking strategy**
   - "What should be mocked?"
   - "How should external dependencies be mocked?"
   - Recommended: Check existing mocking patterns
   - Confidence: [high] if patterns exist

---

## Category 9: Migration & Compatibility

**Purpose**: Handle breaking changes, migrations, and compatibility.

**Dependency**: Only if existing systems are affected.

### Questions

1. **Breaking changes**
   - "Does this introduce breaking changes?"
   - "What will break with this change?"
   - Recommended: Check existing contracts
   - Confidence: [high] if contracts exist

2. **Data migration**
   - "Is data migration needed?"
   - "How should existing data be migrated?"
   - Recommended: Check existing migration patterns
   - Confidence: [high] if patterns exist

3. **Rollback plan**
   - "How should rollback work?"
   - "What's the rollback strategy?"
   - Recommended: Database backup, feature flags
   - Confidence: [judgment-call]

4. **Feature flags**
   - "Are feature flags needed?"
   - "How should feature toggles work?"
   - Recommended: Check existing feature flag system
   - Confidence: [high] if system exists

---

## Category 10: Acceptance

**Purpose**: Define what "done" looks like.

**Dependency**: Should be asked last, after technical details are clear.

### Questions

1. **Done criteria**
   - "What does 'done' look like for this feature?"
   - "How will we know this is complete?"
   - Recommended: Verifiable outcomes
   - Confidence: [your-call]

2. **Verification approach**
   - "How should correctness be verified?"
   - "What tests demonstrate completion?"
   - Recommended: Automated + manual verification
   - Confidence: [high]

3. **Performance benchmarks**
   - "What are the performance benchmarks?"
   - "How will performance be measured?"
   - Recommended: Based on requirements
   - Confidence: [your-call]

4. **Explicit edge cases**
   - "What edge cases must be explicitly tested?"
   - "What boundary conditions must pass?"
   - Recommended: From earlier edge case analysis
   - Confidence: [high]

---

## Question Selection Guidelines

### Ask These (High Priority)
- Scope boundaries
- Architecture decisions
- Data model requirements
- API contract definitions
- Edge cases that could cause failures

### Skip These (Unless Unusual)
- Obvious conventions (follow existing patterns)
- Standard practices (use framework defaults)
- Boilerplate code (scaffold generation)

### Prune When
- User explicitly excludes a category ("no DB needed")
- Codebase investigation provides clear answer
- Question would be redundant with existing info

---

## Confidence Tier Examples

### [high]
- "Where should the new validator live? Recommended: `src/utils/validation.ts` — three sibling validators already live there. Confidence: [high]."

### [judgment-call]
- "Cache TTL for the rate-limiter? Recommended: 60s — short enough that drift stays bounded, long enough that the cache earns its keep. Confidence: [judgment-call]."

### [your-call]
- "What error code should we return when the upstream API times out? Recommended: none — this depends on what callers expect and I don't see existing convention. Confidence: [your-call]."
