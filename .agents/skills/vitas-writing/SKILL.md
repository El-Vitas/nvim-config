---
name: vitas-writing
description: MANDATORY whenever you write or revise prose (a document, a README, an ADR, a PR description, a commit body, a comment reply, an email, a report, or a long chat answer). Covers the tics that make text read as machine-written (colons used as conjunctions, em-dash overuse, inflated vocabulary, uniform rhythm, ceremonial openings, hedged non-positions) and the rules that make writing worth reading (say it once, lead with the conclusion, cut filler, take a position, table vs prose). Trigger on "write", "draft", "document this", "review the style", "this sounds like AI", "remove the tics", "humanize this", "make it shorter", "summarize", and in Spanish on "escribe", "redacta", "documenta esto", "revisa el estilo", "esto suena a IA", "quítale los tics", "humaniza esto", "hazlo más corto", "resume", and whenever you are about to produce more than a few paragraphs of prose. Do not write prose without reading this first.
---

# Vitas Writing

**Write to be understood, not to sound good.** When elegance and clarity conflict, clarity always wins.

This skill covers two different things that reinforce each other.

The first is the tics of automatic writing. A model picks the most probable continuation at every word, and that produces fluent, frictionless prose that says less than it takes up. It is denser to read and poorer in stance than the equivalent written by a person.

The second is writing well, which is an earlier and bigger problem. A text with no tics but full of filler, with the conclusion buried and the same idea said three times, is still a bad text.

Two rules that override the rest:

1. **A tic is not compensated for, it is deleted.** Swapping every em dash for a colon fixes nothing. It replaces one crutch with another.
2. **The rule is checked against the text.** If you cannot point to the sentence that breaks it, it does not belong here.

## Scope

**Applies to:** documents, READMEs, ADRs, PR descriptions, commit bodies, comment replies, emails, reports, and chat answers longer than a few paragraphs.

**Does not apply to:** code, code comments, verbatim quotes, reproduced third-party text, tool output, or trigger metadata. A skill's `description` is written dense in keywords on purpose, because its job is to get the skill activated, not to be read by anyone.

**It cannot:** change what the text claims, invent data, or plant typos or false anecdotes to "sound human". A planted error is a lie about where the text came from, and it shows anyway.

---

## 1. Decorative punctuation

This is the most visible tic, because it shows before anything is read. A reader recognizes the silhouette of a paragraph full of colons and em dashes without having processed a single word.

| ID | Rule | Bad | Good |
|---|---|---|---|
| **WRI-PUN-001** | **A colon announces what comes next, it does not explain what came before.** Using it to wedge in a cause, a consequence or a nuance is replacing a conjunction with a sign | "It is not advisable: it will not be effective" | "It is not advisable because it will not be effective" |
| **WRI-PUN-002** | If replacing the colon with *because*, *so*, a comma or a period leaves the sentence working, the colon was extra | "The result was clear: nobody used it" | "The result was clear. Nobody used it" |
| **WRI-PUN-003** | Never two consecutive sentences with the same colon structure. It is the pattern that gives you away the most | "The team grew: it went to twelve. The cost rose: almost double" | "The team grew to twelve people and the cost almost doubled" |
| **WRI-PUN-004** | Em dash as a wildcard sign: at most one per paragraph. It is almost always a period, a comma or a parenthesis. It is justified when the sentence already uses commas for a list and the dash is what avoids ambiguity | "The plan — which nobody reviewed — failed" | "The plan failed. Nobody had reviewed it" |
| **WRI-PUN-005** | One decorative sign is not swapped for another. When removing an em dash, the rewrite cannot end up with a colon, and the other way around | "The reason was different: the budget" | "The reason was the budget" |
| **WRI-PUN-006** | The parenthesis is no refuge either. If the aside matters, it goes in its own sentence; if it does not matter, it is deleted | "The migration (which took three months) finished" | "The migration finished. It took three months" |

### The three valid uses of the colon

1. **Announcing a list.** *"Three things are missing: the budget, the deadline and the owner."*
2. **Introducing a verbatim quote.** *"The report says it like this: "there is no baseline"."*
3. **Separating a label from its value.** *"Status: active."* This is the use of tables and record cards, not of prose.

Outside those three, the question is which conjunction is hiding behind the sign. It is almost always *because*.

---

## 2. Vocabulary

| ID | Rule | How to verify |
|---|---|---|
| **WRI-LEX-001** | Zero grandiose words that do not change the meaning: *delve, intricate, meticulous, robust, comprehensive, seamless, impeccable, exhaustive, rigorous, invaluable, crucial, pivotal, key, leverage, unlock, navigate (a problem), landscape, ecosystem, synergy, holistic, granular* | Strike the word and reread. If the sentence says the same, it was extra |
| **WRI-LEX-002** | The common word wins. *Utilize* is *use*; *perform* is *do*; *implement* is *do* or *put in place*; *approximately* is *about*; *prior to* is *before* | Substitute the short one and check whether precision is lost |
| **WRI-LEX-003** | Zero filler intensifiers: *extremely, highly, truly, really, absolutely, undoubtedly, incredibly* | Delete them and check that the sentence did not change |
| **WRI-LEX-004** | The quality adjective is replaced by the data that supports it, or deleted | "An efficient process" → "A process with 15% handling time" |
| **WRI-LEX-005** | Nominal style to active voice. The verb goes at the center | "The optimization of the process was carried out" → "We optimized the process" |
| **WRI-LEX-006** | **The passive cannot hide who decides or executes.** A passive with a real verb is not nominal style, and it slips in just the same. In a decision or a commitment, the subject is explicit | "The improvement will be implemented next quarter" → "The platform team implements the improvement next quarter" |
| **WRI-LEX-007** | One word per concept throughout the text. Alternating synonyms to "avoid repetition" is a school reflex that forces the reader to check whether they are the same | List the text's own terms and count their variants |

> The use of *delve*, *intricate* and *meticulous* in PubMed articles spiked in the exact month ChatGPT launched. They are not bad words. They are words a model picks far more often than a person does, and what shows is their repeated presence when the topic does not call for them.

---

## 3. Rhythm

An automatic text has sentences of similar length and paragraphs of similar size. That uniformity is the signal hardest to imitate by hand and the easiest to break.

Each rule comes with both ways of applying it. The middle column is used with hands on the keyboard. The right one, rereading the finished paragraph. The rhythm rules get skipped when they are only stated as a diagnosis, because counting words requires a paragraph that does not exist yet.

| ID | Rule | While writing | While reviewing |
|---|---|---|---|
| **WRI-RIT-001** | Sentence lengths vary within each paragraph | After a long sentence with subordinate clauses, the next one comes out short. On purpose, not whenever it happens | Count words per sentence. If they all fall within a range of five, break it |
| **WRI-RIT-002** | Paragraphs are not all the same size. A one-line paragraph is legitimate | When closing a paragraph, look at the previous one. If two of the same size are in a row, the next one changes | Look at the block from afar. If they form identical bricks, it is wrong |
| **WRI-RIT-003** | Maximum 30 words per sentence | If the sentence is past the second comma and has not closed, close it there. What is left is another sentence | Count those over 30 and split them |
| **WRI-RIT-004** | No listing in threes out of inertia. If the real items are two, two go in | When writing the third item, ask whether it exists or whether the cadence demands it | Look for triads of equal weight: "fast, efficient and secure" |
| **WRI-RIT-005** | Lists do not all have the same number of items or items of the same length, unless the content calls for it | | Compare the lists with each other |

---

## 4. Paragraph structure

| ID | Rule | Bad | Good |
|---|---|---|---|
| **WRI-EST-001** | Start with the fact. No ceremonial opening | "In today's dynamic landscape, organizations face…" | "Three of the five teams did not deliver on time" |
| **WRI-EST-002** | Zero template connectors at the start of a paragraph: *Moreover, Additionally, Furthermore, In addition, On the other hand, In summary, In conclusion, It is worth noting, It is important to note, It bears mentioning* | "Moreover, the cost rose" | "The cost rose" |
| **WRI-EST-003** | Paragraphs are linked by content. If one needs a connector to stick to the previous one, the order is wrong | | |
| **WRI-EST-004** | No closing sentence that restates the paragraph just written | | Delete it. If the paragraph was not understood, the paragraph is rewritten |
| **WRI-EST-005** | The construction "it is not X, it is Y" is only justified when the reader really expected X. If nobody was going to think of X, it is a formula that inflates without correcting anything, and it goes straight to the claim | "The tool is not bad, it is limited" | "The tool does not cover the case of automatic restocking" |
| **WRI-EST-006** | No closing that announces what was already said: *In short, As we have seen, Ultimately, To sum up* | | |

---

## 5. Stance

The tic that shows least and costs most. An automatic text explains a lot and does not commit. It offers the balance instead of the judgment.

| ID | Rule | Bad | Good |
|---|---|---|---|
| **WRI-POS-001** | When there is evidence to take a position, take it | "It is important to weigh the pros and cons of each option" | "Option B, although it costs 20% more, is the only one that does not tie us to the vendor" |
| **WRI-POS-002** | Uncertainty is declared, not dissolved into nuance. Saying *we do not know, and this is what is missing to find out* is a stance; listing considerations is not | | |
| **WRI-POS-003** | Zero escape hatches: *if possible, as appropriate, where applicable, ideally, to the extent possible* | "It will be documented if possible" | "It is documented on every order. If that is not possible, the reason is recorded" |
| **WRI-POS-004** | Zero open-ended terms that cannot be checked: *provide support, manage, optimize, among others, at a minimum, various, several* | "The system manages inventory" | "The system records inbound, outbound and current stock of each spare part" |
| **WRI-POS-005** | If a person signs the text, no experience is invented for them. The data and its source are cited | | |
| **WRI-POS-006** | Zero incomplete references. A pronoun or a collective that the reader cannot resolve without rereading is a gap, not a style | "Everyone agrees the process is critical" | "The six warehouse operators agree the process is critical" |
| **WRI-POS-007** | A figure carries its source, even an informal one. A whole text with no attribution at all cannot be debated, only believed or not | "Turnover rose 20% this year" | "Turnover rose 20% this year, according to payroll" |

---

## 6. Density: what is said and what is cut

This is the half that is not tics. A text clean of crutches but full of filler is still bad.

| ID | Rule | How to verify |
|---|---|---|
| **WRI-DEN-001** | **The conclusion goes first.** Then the development. When there is not one conclusion but several findings with no hierarchy, the first line says how many there are and what they are about, it does not develop them | If you have to read three paragraphs to know what it is about, the order is inverted |
| **WRI-DEN-002** | The title states the finding, not the topic. A title that only names the subject forces you to read the text to know whether it is of interest | "Report on the dispatch process" → "Dispatch has three open problems" |
| **WRI-DEN-003** | **One idea per paragraph** | Count the "also", "in addition", "on the other hand" inside the same paragraph |
| **WRI-DEN-004** | **It is said once.** No summary above and detail below in the same text. If the summary is enough, the detail is extra; if the detail is needed, the summary is extra | Are there two sections that say the same thing at a different zoom? |
| **WRI-DEN-005** | Zero forward references: *this is explained below*, *we will see it later*. If that sentence is needed, the order is inverted | Search for "below", "later", "see section", "we will see" |
| **WRI-DEN-006** | A term is defined at its first appearance, neither before nor after | Read looking for the first time each of the text's own words appears |
| **WRI-DEN-007** | Emphasis is used sparingly. At most two bold spans per paragraph | If everything is bold, nothing stands out |
| **WRI-DEN-008** | Tables for comparable data, prose for reasoning. A table whose last column is paragraphs should be prose | Look at the last column of each table |
| **WRI-DEN-009** | Length is set by purpose, not by the feeling of completeness. A text that grows is split or cut | |
| **WRI-DEN-010** | Zero preamble about what is going to be done. It is done | "I am going to explain three things. First…" → start with the first |
| **WRI-DEN-011** | Zero apologies or courtesy filler that adds nothing: *I hope this helps*, *feel free to reach out*, *as can be seen* | Delete them and check that nothing is missing |

### The skeptical reader test

For each central claim, three questions. If any has no answer in the same paragraph, the sentence is incomplete.

1. **Compared to what?**
2. **How much, in what unit?**
3. **Who measures it and with what data?**

A comparison without all three is written as a pending hypothesis, not as a fact.

---

## 7. How to review

Writing while applying the rules and reviewing with them are two different passes, and both are needed. While writing, the local tics are avoided, which is a word-by-word decision: do not put that sign, do not use that word. While reviewing, the properties of the whole show up (rhythm, repetition, order) that do not exist until the paragraph is finished.

Skipping the second pass leaves a text with no crutches and the conclusion buried. Measured: an agent that applied the standard while writing left zero em dashes and the same five sentences of more than thirty words that it had without the standard.

In this order. The first two steps are done without reading the content.

1. **Look at the shape.** Count colons, em dashes and parentheses. See whether the paragraphs are bricks of the same size. It is detected from afar and does not require understanding the text.
2. **Read aloud.** Ceremonial openings, template connectors and uniform rhythm are heard before they are seen. If reading falls into an announcer's cadence, break it.
3. **Strike words.** Go through looking for those in WRI-LEX-001 and WRI-LEX-003. Strike each one and reread. The one that changes nothing is deleted.
4. **Look for the repeated idea.** Does each central claim appear elsewhere in the text? If so, one of the two is extra.
5. **Look for the stance.** For each central claim, ask what it decides. One that decides nothing is either extra or lacks the judgment.

---

## 8. Self-check before delivering

Each answer comes with the concrete line that supports it. Answering "yes" without pointing to where does not count.

1. How many colons are there, and does each one fall in one of the three valid uses?
2. Does any paragraph have more than one em dash?
3. Was any decorative sign swapped for another instead of rewriting the sentence?
4. Which paragraph starts with a template connector?
5. How many words from WRI-LEX-001 remain, and what does each contribute?
6. Do sentence lengths vary within each paragraph?
7. Is there any triad that was really two items?
8. Does the first line say what it is about?
9. Does any idea appear twice?
10. Where does the text take a stance? Point to the sentence.
11. **Which paragraph is extra?** One has to be named.

> Question 11 is worded that way on purpose. "Is anything extra?" gets answered no by default. "What is extra?" forces a search.

---

## 9. Language

Write in plain international English: no idioms, regional slang or culture-specific references that a non-native reader would have to decode. Prefer *use* over *utilize*, and short common words over rare ones. The text must read the same to any English reader, wherever they are.

Code identifiers, file names and commit messages are in English as well. This skill is about prose, not about that.

---

## Out of scope

**It does not cover evading AI detectors.** Those systems work on statistics. They measure how predictable each word is and how much the rhythm varies, and they are often wrong, especially with technical text and with authors who do not write in their native language.

Writing well reduces the resemblance to a model's output. That is all this skill promises. Chasing a score is chasing the metric instead of the result.

It also does not cover what a document decides or how a set of documents is structured. When the repository has its own documentation guide, that one governs and this one is applied afterwards.

---

## Why it exists

Two reasons, and the second weighs more.

Tics make the text worse, not just recognizable. Colons used as conjunctions force the reader to reconstruct the logical relation the sign hid. Inflated vocabulary lengthens without adding. Uniform rhythm tires. These are real costs for whoever reads, and the resemblance to a model's output is a consequence.

Filler costs more than tics. A text can have not a single extra colon and still waste the reader's time. It is enough to bury the conclusion in the fourth paragraph, say the same idea three ways and close by restating what came before.

That is why the WRI-DEN family exists, and why the self-check ends by forcing you to name a paragraph that is extra.
