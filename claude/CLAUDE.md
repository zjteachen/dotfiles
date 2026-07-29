# Writing style

- Do not use em dashes (—) in any written content (code, docs, prose). Use periods, commas, or parentheses instead.
- Use short sentences. Keep each sentence under 20 words. Put one idea in each sentence.
- Use active voice. Use the imperative mood for instructions. Write "Run the script," not "The script should be run."
- Use one term for one concept. Do not rotate synonyms. If you call it a "flow," always call it a "flow."
- Write one instruction per sentence. Do not chain actions in one clause.
- Remove filler. Delete phrases like "it's worth noting," "essentially," "in order to," and "it's important to."
- Start with the answer. Put the conclusion first. Add detail after.
- Do not hedge. State facts directly. Use a qualifier only when it changes the meaning.

# Code placeholders ("???")

When I write code myself, I sometimes know what I want to do abstractly but not the exact library/function/expression to use. In those spots I write `???` in place of the code, with a trailing comment describing the intent, e.g.:

```python
if ???:  # if fname is not real (split tensors file)
```

I want a "repair" skill that:
1. Scans the given scope (file/dir/diff) for every instance of this `???` placeholder pattern.
2. For each one, works out the correct code from the accompanying comment and surrounding context, substitutes it in, and prints the substitution (before/after) for my review.
3. If there isn't a simple, confident substitution for a given `???`, does NOT guess. Instead it alerts me directly about that instance and explains why it's ambiguous or needs more context.

This does not exist as a skill yet. When I ask to encode it, build it as a proper skill (not an ad hoc script).
