# CloudKit Content Schema

This directory defines the CloudKit schemas that power Bonfire. The Public database hosts shared story content, while the Private database captures each learner's progress, session history, and earned achievements. Schemas can be applied with `cktool` or the CloudKit dashboard, and the development seed can be imported to quickly populate the Development environment with a sample story.

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

## Private Database (User Data)

The Private database captures per-user learning state. All record types live in the default zone of `CKContainer(identifier: "iCloud.com.bonefire.myapp")`.

### Schema Overview

- `UserProfile`
  - **displayName** (`STRING`, optional, searchable)
  - **preferredLocale** (`STRING`)
  - **readingStreak** (`INT64`)
  - **lastSessionAt** (`TIMESTAMP`, optional)
  - _Index_: `by_locale` for filtering preferred locales (used sparingly for analytics aggregates).
- `ReadingSession`
  - **user** (`REFERENCE` → `UserProfile`)
  - **book** (`REFERENCE` → Public `Book`, optional)
  - **startedAt** (`TIMESTAMP`)
  - **endedAt** (`TIMESTAMP`, optional)
  - **durationSeconds** (`INT64`)
  - **wordsRead** (`INT64`, optional)
  - **startPageIndex** (`INT64`, optional)
  - **endPageIndex** (`INT64`, optional)
  - **audioAsset** (`ASSET`, optional, private audio recording of the session)
  - **notes** (`STRING`, optional, searchable)
  - _Indexes_: `by_user_startedAt`, `by_book_startedAt` for timeline and recap queries.
- `WordProgress`
  - **user** (`REFERENCE` → `UserProfile`)
  - **book** (`REFERENCE` → `Book`, optional)
  - **lemma** (`STRING`)
  - **proficiency** (`DOUBLE`)
  - **correctCount** (`INT64`)
  - **incorrectCount** (`INT64`)
  - **lastReviewedAt** (`TIMESTAMP`, optional)
  - _Indexes_: `by_user_lemma`, `by_book` for targeted drills and book review summaries.
- `Achievement`
  - **user** (`REFERENCE` → `UserProfile`)
  - **code** (`STRING`)
  - **earnedAt** (`TIMESTAMP`)
  - **progressValue** (`DOUBLE`, optional)
  - **detail** (`STRING`, optional, searchable)
  - _Indexes_: `by_user_code`, `by_user_earnedAt` for unlocking and ordering badges.
- `BookProgress`
  - **user** (`REFERENCE` → `UserProfile`)
  - **book** (`REFERENCE` → `Book`)
  - **lastPageIndex** (`INT64`)
  - **percentComplete** (`DOUBLE`)
  - **lastOpenedAt** (`TIMESTAMP`, optional)
  - **completedAt** (`TIMESTAMP`, optional)
  - _Indexes_: `by_user_book`, `by_user_lastOpened` for syncing library shelves.

### Applying the Private Schema

```bash
cktool schema import --path Bonfire/Cloud/Schema/PrivateDatabaseSchema.json --environment development --database private
```

### Save Policies

Use `CKModifyRecordsOperation` with the following save policies to avoid overwriting concurrent user changes:

| Record Type    | Save Policy                   | Rationale |
| -------------- | ----------------------------- | --------- |
| `UserProfile`  | `.ifServerRecordUnchanged`    | Preserve streak counters and locale if another device updated the profile. |
| `ReadingSession` | `.ifServerRecordUnchanged`  | Sessions are append-only; this prevents duplicate writes when retrying. |
| `WordProgress` | `.changedKeys`                | Allows partial updates to spaced-repetition metrics without resending unchanged counters. |
| `Achievement`  | `.ifServerRecordUnchanged`    | Avoids double-awarding a badge when syncing across devices. |
| `BookProgress` | `.changedKeys`                | Merge granular reading position changes while letting CloudKit handle conflict resolution per field. |

### Audio Asset Handling

- Session recordings are stored in the `audioAsset` field of `ReadingSession`. Because the asset lives in the Private database, it is only accessible to the signed-in learner.
- To delete a recording, clear the field and submit the change:

  ```swift
  readingSessionRecord[CloudReadingSessionFields.audioAsset] = nil
  let operation = CKModifyRecordsOperation(recordsToSave: [readingSessionRecord], recordIDsToDelete: nil)
  operation.savePolicy = .ifServerRecordUnchanged
  database.add(operation)
  ```

  CloudKit removes the stored asset from the user's private container once the modification succeeds. Mirror this change locally by deleting any cached audio file in the app's sandbox (e.g., `Library/Application Support/ReadingSessions/<recordName>.m4a`).

### Dummy Session Smoke Test

Use the snippet below to create and read back a placeholder session after applying the schema on device:

```swift
let container = CKContainer(identifier: "iCloud.com.bonefire.myapp")
let database = container.privateCloudDatabase

let userRecordID = CKRecord.ID(recordName: "current-user")
let session = CKRecord(recordType: CloudUserRecordType.readingSession)
session[CloudReadingSessionFields.user] = CKRecord.Reference(recordID: userRecordID, action: .none)
session[CloudReadingSessionFields.startedAt] = Date()
session[CloudReadingSessionFields.durationSeconds] = 600

database.save(session) { record, error in
    guard let record else { return }

    database.fetch(withRecordID: record.recordID) { fetched, _ in
        print("Fetched session: \(fetched?.recordID.recordName ?? "<missing>")")
    }
}
```

The call saves a dummy `ReadingSession` and immediately retrieves it, satisfying the acceptance criteria for on-device verification.
