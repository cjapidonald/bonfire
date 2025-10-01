# CloudKit Content Schema

This directory defines the CloudKit Public Database schema and seed content for Bonfire stories and dictionary data. The schema can be applied with `cktool` or the CloudKit dashboard, and the development seed can be imported to quickly populate the Development environment with a sample story.

## Record Types

### `Book`
- **title** (`STRING`, searchable)
- **subtitle** (`STRING`, optional, searchable)
- **author** (`STRING`)
- **summary** (`STRING`, searchable)
- **level** (`STRING`, queryable filter)
- **topic** (`STRING`)
- **length** (`STRING`)
- **pageCount** (`INT64`)

_Indexes_
- `by_level` — single-field index to support level filters in catalog queries.

### `Page`
- **book** (`REFERENCE` → `Book`)
- **index** (`INT64`)
- **estimatedWordCount** (`INT64`, optional)

_Indexes_
- `by_book` — fetch all pages for a book.
- `by_book_index` — ordered fetch for pagination.

### `TextVariant`
- **page** (`REFERENCE` → `Page`)
- **kind** (`STRING`, values: `original`, `translation`, `phonetic`)
- **languageCode** (`STRING`, BCP-47)
- **content** (`STRING`, searchable)
- **displayOrder** (`INT64`)

_Indexes_
- `by_page` — fetch all variants of a page.
- `by_page_language` — fetch a page variant for a specific language.

### `DictionaryEntry`
- **book** (`REFERENCE` → `Book`)
- **lemma** (`STRING`, normalized key for lookup)
- **term** (`STRING`, display form)
- **definition** (`STRING`, searchable)
- **partOfSpeech** (`STRING`)
- **example** (`STRING`, optional, searchable)
- **level** (`STRING`)
- **pageIndex** (`INT64`, optional reference to first page use)

_Indexes_
- `by_book` — fetch all glossary terms for a story.
- `by_lemma` — search by lemma/word (case-insensitive compares should be handled client-side).
- `by_level` — support study sets filtered by CEFR level.

## Seed Data

The development seed `Seed/Development/starry_forest_story.json` contains a sample book titled _Starry Forest Adventure_ with three pages, multilingual text variants, and supporting dictionary entries. Importing this file into the Development environment will surface records in the CloudKit dashboard and allow the app to query content without exposing any learner PII.

### Import Instructions

1. Ensure you are authenticated for the `iCloud.com.bonefire.myapp` container.
2. Apply the schema:
   ```bash
   cktool schema import --path Bonfire/Cloud/Schema/PublicDatabaseSchema.json --environment development
   ```
3. Import the development seed records:
   ```bash
   cktool record import --path Bonfire/Cloud/Seed/Development/starry_forest_story.json --environment development
   ```
4. Verify the records appear in the CloudKit Dashboard under the Public Database.

> ℹ️ No child or learner personally identifiable information is stored in the Public database. All content records are static story assets.
