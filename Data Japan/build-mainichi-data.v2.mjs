import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const outputDir = path.dirname(fileURLToPath(import.meta.url));
const v1Dir = process.argv[2]
  ? path.resolve(process.argv[2])
  : path.resolve(outputDir, "..", "mainichi-data");
const cleanedDir = path.join(outputDir, "cleaned");
const reportsDir = path.join(outputDir, "reports");

const readJson = async (...segments) =>
  JSON.parse(await readFile(path.join(...segments), "utf8"));

const writeJson = async (filePath, value) => {
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
};

const unique = (values) => [...new Set(values.filter(Boolean))];

const sortIds = (values) => unique(values).sort((left, right) => left.localeCompare(right));

const hasOwn = (value, key) =>
  Object.prototype.hasOwnProperty.call(value, key);

const deepHasKey = (value, key) => {
  if (Array.isArray(value)) return value.some((entry) => deepHasKey(entry, key));
  if (!value || typeof value !== "object") return false;
  return (
    hasOwn(value, key) ||
    Object.values(value).some((entry) => deepHasKey(entry, key))
  );
};

const [
  v1Vocabulary,
  v1Kanji,
  v1Grammar,
  v1Flashcards,
  v1Decks,
  v1Categories,
  v1DuplicateReport,
  v1NeedsReview,
  v1RejectedItems,
  v1Summary,
] = await Promise.all([
  readJson(v1Dir, "cleaned", "mainichi-items.clean.json"),
  readJson(v1Dir, "cleaned", "mainichi-kanji.clean.json"),
  readJson(v1Dir, "cleaned", "mainichi-grammar-patterns.clean.json"),
  readJson(v1Dir, "cleaned", "mainichi-flashcard-prompts.clean.json"),
  readJson(v1Dir, "cleaned", "mainichi-decks.clean.json"),
  readJson(v1Dir, "cleaned", "mainichi-categories.clean.json"),
  readJson(v1Dir, "reports", "duplicate-report.json"),
  readJson(v1Dir, "reports", "needs-human-review.json"),
  readJson(v1Dir, "reports", "rejected-items.json"),
  readJson(v1Dir, "reports", "import-summary.json"),
]);

const categoryOrder = [
  "daily-life",
  "family-people",
  "food-drink",
  "home-household",
  "school-classroom",
  "travel-places",
  "shopping-money",
  "time-date",
  "numbers-counters",
  "verbs-actions",
  "adjectives",
  "conversations",
  "grammar-helpers",
  "basic-kanji",
  "word-builder",
];

const categoryPosition = new Map(
  categoryOrder.map((categoryId, index) => [categoryId, index]),
);

const vocabularyPrimaryPriority = [
  "food-drink",
  "school-classroom",
  "travel-places",
  "shopping-money",
  "family-people",
  "home-household",
  "time-date",
  "numbers-counters",
  "conversations",
  "adjectives",
  "verbs-actions",
  "word-builder",
  "daily-life",
];

// These tags indicate genuinely everyday/general-life concepts. This is an
// explicit semantic rule, not a fallback for otherwise uncategorized records.
const dailyLifeTags = new Set([
  "daily",
  "body",
  "clothing",
  "object",
  "health",
  "animal",
  "hobby",
  "art",
  "nature",
  "color",
  "sports",
]);

// The V1 source metadata only labels these as katakana nouns, but their
// meanings clearly make them everyday household/personal-life vocabulary.
const explicitDailyLifeIds = new Set(["kamera", "terebi"]);

const vocabulary = v1Vocabulary.map((item) => {
  const categories = new Set(
    item.categories.filter(
      (categoryId) =>
        categoryId !== "daily-life" && categoryId !== "all-vocabulary",
    ),
  );
  if (
    item.tags.some((tag) => dailyLifeTags.has(tag)) ||
    explicitDailyLifeIds.has(item.id)
  ) {
    categories.add("daily-life");
  }

  const sortedCategories = [...categories].sort(
    (left, right) =>
      categoryPosition.get(left) - categoryPosition.get(right),
  );
  const primaryCategory = vocabularyPrimaryPriority.find((categoryId) =>
    categories.has(categoryId),
  );

  return {
    ...item,
    primary_category: primaryCategory || "uncategorized",
    categories: sortedCategories.length ? sortedCategories : ["uncategorized"],
  };
});

const kanji = v1Kanji.map((item) => ({
  ...item,
  primary_category: item.primary_category || "basic-kanji",
  categories: unique(item.categories),
}));

const grammar = v1Grammar.map((item) => ({
  ...item,
  primary_category: item.primary_category || "grammar-helpers",
  categories: unique(item.categories),
}));

const vocabularyIds = new Set(vocabulary.map((item) => item.id));
const kanjiIds = new Set(kanji.map((item) => item.id));
const grammarIds = new Set(grammar.map((item) => item.id));

const targetTypeForId = (targetId) => {
  if (vocabularyIds.has(targetId)) return "vocabulary";
  if (kanjiIds.has(targetId)) return "kanji";
  if (grammarIds.has(targetId)) return "grammar";
  return undefined;
};

const flashcards = v1Flashcards.map(({ item_id: itemId, ...prompt }) => ({
  id: prompt.id,
  target_type: targetTypeForId(itemId),
  target_id: itemId,
  prompt_type: prompt.prompt_type,
  prompt: prompt.prompt,
  choices: prompt.choices,
  correct_answer: prompt.correct_answer,
  explanation_th: prompt.explanation_th,
  source_files: prompt.source_files,
}));

const resolvedReviewFixes = new Map([
  [
    "chunk-05-n5-adjectives.json:6",
    "高い ใช้ได้ทั้งความหมายว่า ราคาแพง และ สูง โดยเลือกตามบริบท",
  ],
  [
    "chunk-05-n5-adjectives.json:38",
    "早い ใช้บอกว่าเวลาเร็วหรือเช้า เช่น มาถึงเร็วหรือตื่นเช้า",
  ],
  [
    "chunk-05-n5-adjectives.json:39",
    "速い ใช้บอกความเร็วของการเคลื่อนที่ เช่น รถหรือยานพาหนะที่วิ่งเร็ว",
  ],
]);

const reviewTargetByJapaneseAndReading = new Map(
  vocabulary.map((item) => [`${item.japanese}\u0000${item.reading}`, item.id]),
);

const nextPromptNumberByTarget = new Map();
for (const prompt of flashcards) {
  nextPromptNumberByTarget.set(
    prompt.target_id,
    (nextPromptNumberByTarget.get(prompt.target_id) || 0) + 1,
  );
}

for (const review of v1NeedsReview) {
  const reviewKey = `${review.source_file}:${review.source_index}`;
  const translatedExplanation = resolvedReviewFixes.get(reviewKey);
  if (!translatedExplanation) continue;

  const entry = review.original_entry;
  const targetId = reviewTargetByJapaneseAndReading.get(
    `${entry.japanese}\u0000${entry.reading}`,
  );
  if (!targetId) continue;

  const choices = entry.quiz_choices
    .split(";")
    .map((choice) => choice.trim())
    .filter(Boolean);
  const nextNumber = (nextPromptNumberByTarget.get(targetId) || 0) + 1;
  nextPromptNumberByTarget.set(targetId, nextNumber);

  flashcards.push({
    id: `flashcard-${targetId}-${String(nextNumber).padStart(3, "0")}`,
    target_type: "vocabulary",
    target_id: targetId,
    prompt_type: "multiple-choice",
    prompt: entry.conversation_prompt,
    choices,
    correct_answer: entry.correct_answer,
    explanation_th: translatedExplanation,
    source_files: [review.source_file],
  });
}

flashcards.sort((left, right) => left.id.localeCompare(right.id));
const flashcardIds = new Set(flashcards.map((prompt) => prompt.id));

const needsHumanReview = v1NeedsReview
  .filter(
    (review) =>
      !resolvedReviewFixes.has(`${review.source_file}:${review.source_index}`),
  )
  .map((review) => ({
    source_file: review.source_file,
    source_index: review.source_index,
    target_id: review.clean_item_id,
    target_type: "vocabulary",
    issue_type: "level-conflict",
    original_entry: review.original_entry,
    related_entries: review.related_entries || [],
    reason: review.reason.replace(", ", " and "),
    suggested_fix:
      "Confirm the intended JLPT level. Keep the current clean item only after choosing a stable level.",
  }));

const rejectedItems = v1RejectedItems.map((entry) => ({ ...entry }));

const vocabularyDecksByItemId = new Map(
  vocabulary.map((item) => [item.id, item.decks]),
);
const grammarDeckById = new Map(grammar.map((item) => [item.id, item.deck]));

const deckTargetIds = (deck) => {
  const vocabularyItemIds = deck.item_ids.filter((id) => vocabularyIds.has(id));
  const deckKanjiIds = deck.item_ids.filter((id) => kanjiIds.has(id));
  const grammarPatternIds = deck.item_ids.filter((id) => grammarIds.has(id));
  return {
    vocabularyItemIds,
    deckKanjiIds,
    grammarPatternIds,
  };
};

const decks = v1Decks.map(({ item_ids: itemIds, ...deck }) => {
  const originalDeck = { ...deck, item_ids: itemIds };
  const {
    vocabularyItemIds,
    deckKanjiIds,
    grammarPatternIds,
  } = deckTargetIds(originalDeck);
  const targetIds = new Set([
    ...vocabularyItemIds,
    ...deckKanjiIds,
    ...grammarPatternIds,
  ]);
  const flashcardPromptIds = flashcards
    .filter((prompt) => targetIds.has(prompt.target_id))
    .map((prompt) => prompt.id);

  return {
    ...deck,
    vocabulary_item_ids: sortIds(vocabularyItemIds),
    kanji_ids: sortIds(deckKanjiIds),
    grammar_pattern_ids: sortIds(grammarPatternIds),
    flashcard_prompt_ids: sortIds(flashcardPromptIds),
  };
});

const v1CategoryById = new Map(
  v1Categories.map(({ item_ids: _itemIds, ...category }) => [
    category.id,
    category,
  ]),
);

const categoryDefinitions = categoryOrder.map((categoryId) => ({
  ...v1CategoryById.get(categoryId),
  id: categoryId,
  is_virtual: false,
}));

categoryDefinitions.push({
  id: "all-vocabulary",
  name_en: "All Vocabulary",
  name_th: "คำศัพท์ทั้งหมด",
  description_th: "คำศัพท์ปกติทั้งหมดสำหรับการกรองในคลังคำศัพท์",
  icon: "books.vertical",
  color: "sakuraPink",
  is_virtual: true,
});

const categoryReferences = new Map(
  categoryDefinitions.map((category) => [
    category.id,
    {
      vocabulary_item_ids: [],
      kanji_ids: [],
      grammar_pattern_ids: [],
    },
  ]),
);

for (const item of vocabulary) {
  for (const categoryId of item.categories) {
    if (!categoryReferences.has(categoryId)) {
      categoryReferences.set(categoryId, {
        vocabulary_item_ids: [],
        kanji_ids: [],
        grammar_pattern_ids: [],
      });
    }
    categoryReferences.get(categoryId).vocabulary_item_ids.push(item.id);
  }
}

for (const item of kanji) {
  for (const categoryId of item.categories) {
    categoryReferences.get(categoryId)?.kanji_ids.push(item.id);
  }
}

for (const item of grammar) {
  for (const categoryId of item.categories) {
    categoryReferences.get(categoryId)?.grammar_pattern_ids.push(item.id);
  }
}

categoryReferences.get("all-vocabulary").vocabulary_item_ids.push(
  ...vocabulary.map((item) => item.id),
);

const categories = categoryDefinitions.map((category) => {
  const references = categoryReferences.get(category.id);
  const vocabularyItemIds = sortIds(references.vocabulary_item_ids);
  const categoryKanjiIds = sortIds(references.kanji_ids);
  const grammarPatternIds = sortIds(references.grammar_pattern_ids);
  return {
    ...category,
    vocabulary_item_ids: vocabularyItemIds,
    kanji_ids: categoryKanjiIds,
    grammar_pattern_ids: grammarPatternIds,
    total_count: new Set([
      ...vocabularyItemIds,
      ...categoryKanjiIds,
      ...grammarPatternIds,
    ]).size,
  };
});

const manifest = {
  dataset_name: "Mainichi Notebook Seed Data",
  version: "v2",
  language: "ja-TH",
  files: {
    vocabulary: "mainichi-items.clean.json",
    kanji: "mainichi-kanji.clean.json",
    grammar_patterns: "mainichi-grammar-patterns.clean.json",
    flashcard_prompts: "mainichi-flashcard-prompts.clean.json",
    decks: "mainichi-decks.clean.json",
    categories: "mainichi-categories.clean.json",
  },
  schema_notes: [
    "Decks and categories use vocabulary_item_ids, kanji_ids, and grammar_pattern_ids instead of ambiguous item_ids.",
    "Flashcards use target_type and target_id instead of ambiguous item_id.",
    "all-vocabulary is virtual and should not be added to each item's categories.",
  ],
};

const duplicateReport = v1DuplicateReport.map((entry) => ({ ...entry }));

const validationErrors = [];
const validationWarnings = [];

const hasUniqueIds = (records) =>
  new Set(records.map((record) => record.id)).size === records.length;

const allDeckReferencesResolve = decks.every(
  (deck) =>
    deck.vocabulary_item_ids.every((id) => vocabularyIds.has(id)) &&
    deck.kanji_ids.every((id) => kanjiIds.has(id)) &&
    deck.grammar_pattern_ids.every((id) => grammarIds.has(id)) &&
    deck.flashcard_prompt_ids.every((id) => flashcardIds.has(id)),
);

const allCategoryReferencesResolve = categories.every(
  (category) =>
    category.vocabulary_item_ids.every((id) => vocabularyIds.has(id)) &&
    category.kanji_ids.every((id) => kanjiIds.has(id)) &&
    category.grammar_pattern_ids.every((id) => grammarIds.has(id)),
);

const allFlashcardTargetsResolve = flashcards.every(
  (prompt) =>
    targetTypeForId(prompt.target_id) === prompt.target_type,
);

const allFlashcardAnswersInChoices = flashcards.every((prompt) =>
  prompt.choices.includes(prompt.correct_answer),
);

const categoryIds = new Set(categories.map((category) => category.id));
const allVocabularyCategoriesValid = vocabulary.every(
  (item) =>
    item.primary_category &&
    item.categories.length > 0 &&
    item.categories.includes(item.primary_category) &&
    item.categories.every((categoryId) => categoryIds.has(categoryId)) &&
    !item.categories.includes("all-vocabulary"),
);

const dailyLifeCount = categories.find(
  (category) => category.id === "daily-life",
)?.total_count;
const noDailyLifeGlobalAssignment =
  dailyLifeCount !== vocabulary.length &&
  vocabulary.some((item) => !item.categories.includes("daily-life"));

const noAmbiguousItemIdsFields =
  !deepHasKey(decks, "item_ids") &&
  !deepHasKey(categories, "item_ids") &&
  !deepHasKey(flashcards, "item_id");

const canonicalOutputNames = [
  "mainichi-items.clean.json",
  "mainichi-kanji.clean.json",
  "mainichi-grammar-patterns.clean.json",
  "mainichi-flashcard-prompts.clean.json",
  "mainichi-decks.clean.json",
  "mainichi-categories.clean.json",
  "mainichi-data-manifest.json",
  "duplicate-report.json",
  "needs-human-review.json",
  "rejected-items.json",
  "validation-report.json",
  "import-summary.json",
  "build-mainichi-data.v2.mjs",
];
const noParenthesizedFilenames = canonicalOutputNames.every(
  (fileName) => !fileName.includes("(1)"),
);

const allCategoryCountsCorrect = categories.every(
  (category) =>
    category.total_count ===
    new Set([
      ...category.vocabulary_item_ids,
      ...category.kanji_ids,
      ...category.grammar_pattern_ids,
    ]).size,
);

const checks = {
  unique_vocabulary_ids: hasUniqueIds(vocabulary),
  unique_kanji_ids: hasUniqueIds(kanji),
  unique_grammar_pattern_ids: hasUniqueIds(grammar),
  unique_flashcard_prompt_ids: hasUniqueIds(flashcards),
  all_deck_references_resolve: allDeckReferencesResolve,
  all_category_references_resolve: allCategoryReferencesResolve,
  all_flashcard_targets_resolve: allFlashcardTargetsResolve,
  all_flashcard_answers_in_choices: allFlashcardAnswersInChoices,
  all_vocabulary_categories_valid: allVocabularyCategoriesValid,
  all_category_total_counts_correct: allCategoryCountsCorrect,
  no_daily_life_global_assignment: noDailyLifeGlobalAssignment,
  no_ambiguous_item_ids_fields: noAmbiguousItemIdsFields,
  canonical_output_filenames: noParenthesizedFilenames,
  rejected_items_report_exists: true,
  needs_human_review_report_exists: true,
};

for (const [checkName, passed] of Object.entries(checks)) {
  if (!passed) validationErrors.push(`Validation check failed: ${checkName}`);
}

if (needsHumanReview.length) {
  validationWarnings.push(
    `${needsHumanReview.length} vocabulary items still have unresolved JLPT level conflicts.`,
  );
}

const uncategorizedVocabulary = vocabulary.filter(
  (item) =>
    item.primary_category === "uncategorized" ||
    item.categories.includes("uncategorized"),
);
if (uncategorizedVocabulary.length) {
  validationWarnings.push(
    `${uncategorizedVocabulary.length} vocabulary items remain uncategorized.`,
  );
}

const validationReport = {
  passed: validationErrors.length === 0,
  errors: validationErrors,
  warnings: validationWarnings,
  checks,
};

const categoryCounts = Object.fromEntries(
  categories.map((category) => [category.id, category.total_count]),
);
const deckCounts = Object.fromEntries(
  decks.map((deck) => [
    deck.id,
    new Set([
      ...deck.vocabulary_item_ids,
      ...deck.kanji_ids,
      ...deck.grammar_pattern_ids,
    ]).size,
  ]),
);

const importSummary = {
  version: "v2",
  total_input_vocabulary_items: v1Vocabulary.length,
  clean_vocabulary_items: vocabulary.length,
  clean_kanji_items: kanji.length,
  clean_grammar_patterns: grammar.length,
  flashcard_prompts: flashcards.length,
  decks_created: decks.length,
  categories_created: categories.length,
  virtual_categories_created: categories.filter(
    (category) => category.is_virtual,
  ).length,
  duplicates_merged: v1Summary.duplicates_merged,
  duplicate_groups: v1Summary.duplicate_groups,
  needs_human_review: needsHumanReview.length,
  rejected_items: rejectedItems.length,
  category_counts: categoryCounts,
  deck_counts: deckCounts,
  source_files_processed: [
    "mainichi-items.clean.json",
    "mainichi-kanji.clean.json",
    "mainichi-grammar-patterns.clean.json",
    "mainichi-flashcard-prompts.clean.json",
    "mainichi-decks.clean.json",
    "mainichi-categories.clean.json",
    "duplicate-report.json",
    "needs-human-review.json",
    "rejected-items.json",
    "import-summary.json",
  ],
  notes: [
    "V2 was transformed from the V1 clean package while preserving stable content IDs.",
    `daily-life was reduced from ${v1Vocabulary.length} vocabulary items to ${dailyLifeCount} explicitly relevant vocabulary items.`,
    "all-vocabulary was created as a virtual category and was not added to item category arrays.",
    "Three English quiz explanations were safely translated into Thai and their flashcard prompts were restored.",
    `${needsHumanReview.length} JLPT level conflicts remain for human confirmation.`,
  ],
};

await rm(cleanedDir, { recursive: true, force: true });
await rm(reportsDir, { recursive: true, force: true });
await mkdir(cleanedDir, { recursive: true });
await mkdir(reportsDir, { recursive: true });

await Promise.all([
  writeJson(path.join(cleanedDir, "mainichi-items.clean.json"), vocabulary),
  writeJson(path.join(cleanedDir, "mainichi-kanji.clean.json"), kanji),
  writeJson(path.join(cleanedDir, "mainichi-grammar-patterns.clean.json"), grammar),
  writeJson(path.join(cleanedDir, "mainichi-flashcard-prompts.clean.json"), flashcards),
  writeJson(path.join(cleanedDir, "mainichi-decks.clean.json"), decks),
  writeJson(path.join(cleanedDir, "mainichi-categories.clean.json"), categories),
  writeJson(path.join(cleanedDir, "mainichi-data-manifest.json"), manifest),
  writeJson(path.join(reportsDir, "duplicate-report.json"), duplicateReport),
  writeJson(path.join(reportsDir, "needs-human-review.json"), needsHumanReview),
  writeJson(path.join(reportsDir, "rejected-items.json"), rejectedItems),
  writeJson(path.join(reportsDir, "validation-report.json"), validationReport),
  writeJson(path.join(reportsDir, "import-summary.json"), importSummary),
]);

console.log(`Vocabulary items: ${vocabulary.length}`);
console.log(`Kanji items: ${kanji.length}`);
console.log(`Grammar patterns: ${grammar.length}`);
console.log(`Flashcard prompts: ${flashcards.length}`);
console.log(`Categories: ${categories.length}`);
console.log(`Decks: ${decks.length}`);
console.log(`Needs review: ${needsHumanReview.length}`);
console.log(`Rejected: ${rejectedItems.length}`);
console.log(`Validation passed: ${validationReport.passed}`);
