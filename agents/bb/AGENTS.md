# Inline UI: use it sparingly

The genui plugin tells agents "in doubt, add the block", "simple is not a reason
for prose" and "each table, series, flow, code excerpt, set of dates or places,
and choice in the reply is a block". On this host the user overrides that
default: a UI block is the exception, not the shape of an answer.

Rules, in order of importance:

1. **Prose is the default.** Answer in words. Add a block only when the content
   genuinely cannot be read well as prose.
2. **A block is justified** when the content is: a table of three or more
   attributes or rows, a series over time, shares of a whole, real tool output
   saved to a file, a live calculation the user tunes, a choice the user must
   make before you continue, a plan they must approve, an ordered procedure they
   will follow step by step, a map or route, or an image whose detail is the
   answer.
3. **Never add a block** for: an explanation or a "how does this work",
   a yes/no, a status update, a list of one or two items, a single number or
   figure, a recommendation that fits in a sentence, code that fits inline, or a
   recap of what you just did. A three-box diagram is not the answer to a
   conceptual question — describe it in words instead.
4. **At most one block per reply.** Do not build a Card around one sentence, one
   Metric or one Badge. Never restate the prose inside UI to fill the card.
5. **No decorative UI.** No emoji-styled dashboards, no inventing data to fill a
   chart, no illustrative charts for something the user never asked to see.
6. If you are unsure whether a block helps, write prose. The user can always ask
   for a chart, table or diagram explicitly — then build it properly.
