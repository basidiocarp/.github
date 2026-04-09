# Reports Templates

This folder contains report and planning templates that are meant to be usable by both people and AI systems. The templates provide structure and prompt language, but the finished document should read like a normal document written for humans.

Each template has a matching example in `examples/`. Use the example when you want to see the intended level of detail, tone, and section flow before drafting a real document.

## Templates

### Executive Incident Report

Use this when the audience is leadership, management, or stakeholders who need the business picture quickly. Keep the writing short, direct, and decision-oriented.

- Template: `EXECUTIVE-INCIDENT-REPORT-TEMPLATE.md`
- Example: `examples/EXECUTIVE-INCIDENT-REPORT-EXAMPLE.md`

### Internal Incident Report

Use this when the audience is engineering, operations, support, or anyone who needs the fuller incident record. Keep the writing concrete and factual. Include the technical story, but do not turn it into a dump of notes.

- Template: `INTERNAL-INCIDENT-REPORT-TEMPLATE.md`
- Example: `examples/INTERNAL-INCIDENT-REPORT-EXAMPLE.md`

### Project Plan

Use this for stakeholder-facing planning. The focus is scope, outcomes, risks, timeline, and ownership. It should explain what will happen and why it matters without drifting into engineering implementation detail.

- Template: `PROJECT-PLAN-TEMPLATE.md`
- Example: `examples/PROJECT-PLAN-EXAMPLE.md`

### Technical Project Plan

Use this for the engineering plan behind a project. The focus is current-state problems, technical approach, migration or rollout strategy, testing, and exit criteria.

- Template: `TECHNICAL-PROJECT-PLAN-TEMPLATE.md`
- Example: `examples/TECHNICAL-PROJECT-PLAN-EXAMPLE.md`

## Writing Guidance

- Lead with the point. A reader should understand the situation from the first paragraph.
- Use exact dates instead of relative dates.
- Prefer concrete language over abstract claims.
- Keep sections focused on their audience. Executive documents should not read like engineering notes, and technical documents should not hide behind vague business language.
- If AI is filling in a draft, edit the result so the final document reads naturally and reflects what actually happened.

## How To Use These

1. Pick the template that matches the audience.
2. Read the matching example before drafting.
3. Fill in the template with real details, not placeholders dressed up as prose.
4. Do one editing pass for tone and one for accuracy.

If a document starts sounding generic, it usually means the details are too vague or the audience is not defined clearly enough.
