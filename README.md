# 🌸 Mainichi Notebook (毎日ノート)

### A Japanese Study Hub & Digital Notebook for iPadOS & iOS

[![Swift](https://img.shields.io/badge/Swift-Native-orange.svg?style=flat-square\&logo=swift)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iPadOS%2016%2B%20%7C%20iOS%2016%2B-blue.svg?style=flat-square\&logo=apple)](https://developer.apple.com)
[![UI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20UIKit-purple.svg?style=flat-square\&logo=apple)](https://developer.apple.com)
[![Frameworks](https://img.shields.io/badge/Apple-PencilKit%20%7C%20PDFKit%20%7C%20AVFoundation-lightgrey.svg?style=flat-square)](https://developer.apple.com)
[![Storage](https://img.shields.io/badge/Storage-Local--First-success.svg?style=flat-square)](#privacy--data)
[![Dependencies](https://img.shields.io/badge/Third--Party%20Dependencies-None-brightgreen.svg?style=flat-square)](#technical-overview)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat-square)](LICENSE)

<p align="center">
  <img src="Screenshots/01_Home/home_dashboard.png" width="100%" alt="Mainichi Notebook Home Dashboard" />
</p>

**Mainichi Notebook** is an iPad-first Japanese learning app that brings handwritten notes, vocabulary study, handwriting practice, spaced-repetition flashcards, and daily study planning into one cohesive workspace.

It was designed around a simple idea:

> Studying Japanese should not require jumping between five different apps.

---

<details>
<summary><b>🌸 The Story Behind Mainichi Notebook</b></summary>
<br/>

Mainichi Notebook started as an anniversary gift for my partner, who has been studying Japanese.

While watching their study routine, I noticed how fragmented the experience could become: lecture notes in one app, flashcards in another, handwriting practice somewhere else, and pronunciation tools scattered across different services.

I wanted to design something that felt more personal and more focused.

The result is an all-in-one Japanese study environment built around the iPad — combining Apple Pencil note-taking, vocabulary management, handwriting practice, spaced repetition, and everyday study planning while keeping the visual experience warm and approachable.

</details>

---

## Table of Contents

* [Overview](#overview)
* [Design Goals](#design-goals)
* [Features](#features)

  * [Lectures & Digital Notebook](#1--lectures--digital-notebook)
  * [Paper Template Library](#2--paper-template-library)
  * [Annotations, Stickers & PDF Notes](#3--annotations-stickers--pdf-notes)
  * [Home Dashboard & Study Planner](#4--home-dashboard--study-planner)
  * [Vocabulary Library](#5--vocabulary-library)
  * [Kana & Kanji Writing Practice](#6--kana--kanji-writing-practice)
  * [Thematic Vocabulary Packs](#7--thematic-vocabulary-packs)
  * [Daily Summary](#8--daily-summary)
  * [SRS & Flashcards](#9--srs--flashcards)
  * [Settings & Themes](#10--settings--themes)
* [Technical Overview](#technical-overview)
* [Engineering Highlights](#engineering-highlights)
* [Project Structure](#project-structure)
* [Getting Started](#getting-started)
* [Privacy & Data](#privacy--data)
* [Development Approach](#development-approach)
* [License](#license)

---

# Overview

Mainichi Notebook (毎日ノート) is a native Swift application designed primarily for **Japanese learners using iPad and Apple Pencil**.

Rather than treating note-taking, vocabulary review, handwriting, flashcards, and study tracking as separate activities, the app connects them inside one study environment.

The interface uses a warm Japanese-inspired visual language built around soft paper tones, cherry-blossom pink, muted green, dark navy, and wooden bookshelf elements.

### Main study modules

| Module               | Purpose                                              |
| -------------------- | ---------------------------------------------------- |
| 📝 Lectures          | Handwritten notebooks and imported study material    |
| 📚 Vocabulary        | Browse, search, save, and create Japanese vocabulary |
| ✍️ Writing Practice  | Practice Hiragana, Katakana, and Kanji               |
| 🗂 Simple Vocabulary | Study themed vocabulary collections                  |
| 📊 Daily Summary     | Track study activity and daily goals                 |
| 🧠 Flashcards        | Review vocabulary with spaced repetition             |

The application is **iPad-first** and designed around larger-screen study sessions, while supporting the iOS target as well.

---

# Design Goals

### ✏️ Handwriting should feel native

Apple Pencil is treated as a core input method rather than an optional extra.

The notebook workspace combines **PencilKit** with custom UIKit gesture handling for drawing, panning, and zooming.

### 🧠 Studying should connect naturally

Vocabulary can move into flashcard review, handwriting practice contributes to daily progress, and the dashboard brings multiple study activities together in one place.

### 🌸 Learning tools do not have to look clinical

The UI intentionally avoids the typical productivity-dashboard aesthetic.

Bookshelves, paper textures, muted colors, Japanese typography, stickers, and physical notebook references are used to make the app feel closer to a personal study desk.

### 🔒 Personal study data should stay personal

The current app does not require an account or remote backend.

Notes, progress records, preferences, and study state are designed around local device storage.

---

# Features

## 1. 📝 Lectures & Digital Notebook

The Lectures module is the main handwritten notebook workspace.

Instead of displaying notebooks as a standard file list, Mainichi Notebook presents them on a visual wooden bookshelf.

### Features

* Custom notebook covers
* Japanese and English notebook titles
* Subject categories
* Page counters
* Recently opened notebooks
* Add, delete, and reorder pages
* Collapsible page-thumbnail navigation
* Apple Pencil handwriting
* Pinch-to-zoom and canvas panning
* Multiple writing tools
* Persistent notebook storage

### Drawing tools

The notebook supports multiple PencilKit-based writing styles, including:

* Study Pen
* Fountain Pen
* Calligraphy Brush
* Pencil
* Highlighter
* Eraser

A custom SwiftUI/UIKit bridge coordinates the drawing canvas with the surrounding zoomable workspace.

<p align="center">
  <img src="Screenshots/02_Lectures/lectures_bookshelf.png" width="49%" alt="Lectures Bookshelf" />
  <img src="Screenshots/02_Lectures/lecture_canvas_editor.png" width="49%" alt="Lecture Canvas Editor" />
</p>

---

## 2. 📑 Paper Template Library

Not every type of Japanese study works well on blank paper.

Mainichi Notebook includes several study-oriented paper templates that can be applied directly to notebook pages.

### Built-in templates

* **Genkouyoushi (原稿用紙)**
  Traditional Japanese manuscript-style grid paper.

* **Cornell Notes**
  Structured layout containing cue, note, and summary sections.

* **Kana Practice Grid**
  Character boxes with alignment guides.

* **Kanji Practice Grid**
  Quadrant-based writing guides for character proportions.

* **Grammar Pattern Sheet**
  Structured areas for grammar rules and conjugation notes.

* **Ruled Paper**

* **Classic Grid**

* **Dot Grid**

* **Blank Paper**

Templates are drawn as scalable vector-based layouts so they remain sharp at different zoom levels.

Users can also import their own paper backgrounds and study materials from device storage.

<p align="center">
  <img src="Screenshots/02_Lectures/lecture_template_library.png" width="70%" alt="Paper Template Library" />
</p>

---

## 3. 🎨 Annotations, Stickers & PDF Notes

Notebook pages support more than handwriting.

Study material can be arranged directly on the page using several annotation types.

### Japanese-themed stickers

Included decorative elements feature themes such as:

* 🌸 Sakura
* ⛩️ Torii
* 🗻 Mount Fuji
* 🏮 Chōchin
* 🦊 Kitsune
* 🍵 Matcha
* 🍣 Sushi
* Study achievement stamps

### Sticky notes

Typed Post-it-style notes can be placed around the notebook page for:

* reminders
* grammar explanations
* vocabulary notes
* translations
* study questions

### Images

Reference images can be imported from the photo library and positioned alongside handwritten notes.

### PDF study material

PDF handouts and lecture documents can be imported and used as page backgrounds for handwritten annotation.

### Page export

Notebook pages can be rendered into a flattened image combining:

* paper template
* handwriting
* stickers
* images
* sticky notes

The result can then be exported through the native iOS Share Sheet.

<p align="center">
  <img src="Screenshots/02_Lectures/lecture_stickers_modal.png" width="70%" alt="Notebook Stickers and Annotations" />
</p>

---

## 4. 🏠 Home Dashboard & Study Planner

The Home screen acts as the central overview for the learner's day.

It combines quick navigation with study progress, upcoming work, and personal planning.

### Dashboard features

* Japanese greeting
* User profile
* Daily streak
* Best streak
* Today's study progress
* Study-time tracking
* Mood check-in
* Recent lecture notebooks
* Upcoming flashcard reviews
* Today's study plan
* Quick access to every study module
* Japanese proverb of the day

### Daily progress

Four core activities contribute to the dashboard's daily progress indicator:

* Lectures
* Vocabulary
* Writing Practice
* Flashcard Review

### Study planner

Today's Plan provides a lightweight checklist for organizing study sessions and estimating how much time is planned for the day.

<p align="center">
  <img src="Screenshots/01_Home/home_dashboard.png" width="49%" alt="Mainichi Notebook Dashboard" />
  <img src="Screenshots/01_Home/home_todays_plan.png" width="49%" alt="Today's Study Plan" />
</p>

---

## 5. 📚 Vocabulary Library

Mainichi Notebook includes a searchable vocabulary library for studying Japanese words across multiple JLPT levels and everyday categories.

### Vocabulary data

The bundled library contains **528+ vocabulary entries** with information such as:

* Kanji
* Hiragana reading
* Romaji
* English meaning
* Thai meaning
* Part of speech
* JLPT level
* Example sentences
* Furigana information

### Search & filtering

Vocabulary can be browsed and filtered using different study criteria.

### Word detail panel

Selecting a word opens a dedicated detail view containing its available linguistic information and study actions.

From here, vocabulary can be:

* bookmarked
* added to flashcards
* reviewed with pronunciation
* inspected through example sentences

### Japanese pronunciation

Pronunciation uses Apple's native speech synthesis through:

```swift
AVSpeechSynthesizer
```

with Japanese language output using `ja-JP`.

### Custom vocabulary

Users can also create their own vocabulary entries with:

* Japanese term
* reading
* romaji
* English / Thai meaning
* JLPT level
* part of speech
* example sentence

<p align="center">
  <img src="Screenshots/03_Vocabulary/vocab_library.png" width="49%" alt="Vocabulary Library" />
  <img src="Screenshots/03_Vocabulary/vocab_detail_drawer.png" width="49%" alt="Vocabulary Detail Panel" />
</p>

<p align="center">
  <img src="Screenshots/03_Vocabulary/vocab_add_modal.png" width="65%" alt="Custom Vocabulary Creator" />
</p>

---

## 6. ✍️ Kana & Kanji Writing Practice

The Writing Practice module focuses on learning character shape and stroke order through repeated handwriting.

### Gojūon browser

An interactive 50-sound layout covers the main Hiragana and Katakana rows:

* A
* Ka
* Sa
* Ta
* Na
* Ha
* Ma
* Ya
* Ra
* Wa

### Stroke-order visualization

Character strokes are represented using vector paths and displayed step by step.

The interface can show:

* stroke sequence
* directional movement
* stroke numbers
* writing guides

### Tracing canvas

Learners can write directly over character guides using Apple Pencil or touch input.

The canvas supports clearing and repeating characters as many times as needed.

### Audio

Characters can be pronounced using native Japanese speech synthesis for simultaneous writing and pronunciation practice.

<p align="center">
  <img src="Screenshots/04_WritingPractice/writing_hiragana_grid.png" width="49%" alt="Hiragana Practice Grid" />
  <img src="Screenshots/04_WritingPractice/writing_kanji_canvas.png" width="49%" alt="Kanji Writing Practice" />
</p>

---

## 7. 🗂 Thematic Vocabulary Packs

Simple Vocabulary provides smaller, focused collections for shorter study sessions.

Instead of browsing the entire vocabulary database, learners can work through vocabulary grouped by topic.

### Example packs

* 500 Essential Words
* JLPT N5 Beginner
* Japanese Word Builder
* Daily Life
* Greetings & Everyday Conversation
* Food & Dining
* Shopping
* Classroom Survival

Each pack can display study progress such as:

* cards viewed
* completion progress
* memorized words
* bookmarked words

<p align="center">
  <img src="Screenshots/05_SimpleVocabulary/simple_vocab_packs.png" width="70%" alt="Thematic Vocabulary Packs" />
</p>

---

## 8. 📊 Daily Summary

The Daily Summary screen gives learners a lightweight view of their study activity.

### Daily metrics

The interface tracks several activities, including:

* study minutes
* flashcards reviewed
* bookmarked vocabulary
* custom vocabulary created
* kana / character practice
* vocabulary pack progress

### Quick study-time logging

Study time can be added using quick controls such as:

```text
+5 min
+10 min
+15 min
+30 min
```

### Daily habits

A checklist provides a simple way to mark common study goals such as:

* reviewing flashcards
* practicing writing
* studying vocabulary
* completing notebook work

<p align="center">
  <img src="Screenshots/06_DailySummary/daily_summary_tracker.png" width="70%" alt="Daily Study Summary" />
</p>

---

## 9. 🧠 SRS & Flashcards

Mainichi Notebook includes a custom **SM-2-inspired spaced-repetition scheduler** for vocabulary review.

The implementation borrows the core idea of adjusting future review intervals according to recall difficulty, but it is **not a verbatim implementation of the original SuperMemo-2 formula**.

### Review states

Cards can move through states such as:

* New
* Learning
* Review
* Relearning

The Flashcard dashboard organizes study material into groups such as:

* Due Today
* New Words
* Learning
* Review
* Saved

### Review ratings

After a review, the learner can rate recall using four levels:

| Rating    | Meaning                        |
| --------- | ------------------------------ |
| **Again** | The card was forgotten         |
| **Hard**  | The answer was difficult       |
| **Good**  | The card was recalled normally |
| **Easy**  | The card was recalled easily   |

### Initial scheduling

For a card being reviewed for the first time:

| Rating | Next Review |
| ------ | ----------: |
| Again  |  10 minutes |
| Hard   |       1 day |
| Good   |      2 days |
| Easy   |      4 days |

### Later reviews

Existing cards use their current interval and ease factor to calculate the next review.

Conceptually:

```text
Again → return to relearning and review again after 10 minutes

Hard  → interval × 1.2

Good  → interval × ease factor

Easy  → interval × ease factor × 1.6
```

The ease factor is adjusted according to review difficulty and is clamped to prevent it from becoming too small.

This keeps the scheduler predictable while still allowing easier cards to gradually receive longer review intervals.

### Quiz modes

Mainichi Notebook includes six quiz configurations:

1. **Preloaded Prompts**
   Hand-authored study questions.

2. **Japanese → Meaning**
   See the Japanese word and identify its meaning.

3. **Meaning → Japanese**
   Start from a meaning and identify the Japanese word.

4. **Reading → Meaning**
   Practice recognition from Kana without relying on Kanji.

5. **Meaning → Reading**
   Recall the correct Japanese reading.

6. **Mixed Practice**
   Combine multiple question types within the same session.

### Quiz options

Depending on the study mode, the interface can display or hide:

* Furigana
* Romaji
* Example sentences
* Audio pronunciation

Question order can also be shuffled for less predictable review sessions.

<p align="center">
  <img src="Screenshots/07_Flashcards/flashcards_overview.png" width="49%" alt="Flashcards Dashboard" />
  <img src="Screenshots/07_Flashcards/flashcards_mode_config.png" width="49%" alt="Flashcard Study Modes" />
</p>

<p align="center">
  <img src="Screenshots/07_Flashcards/flashcards_quiz_session.png" width="70%" alt="Flashcard Quiz Session" />
</p>

---

## 10. ⚙️ Settings & Themes

Mainichi Notebook includes personalization options for both study preferences and appearance.

### Appearance

The visual system is based around reusable semantic colors such as:

* Sakura Pink
* Sage / Matcha Green
* Warm Paper
* Wood tones
* Deep Navy

### Light & Dark Mode

The application contains dedicated light and dark appearance values so the same study interface can adapt to different environments.

### Feedback

Sound and haptic feedback can be enabled or disabled for supported interactions.

### Study reminders

Local notifications can be configured for study reminders without requiring an external notification server.

<p align="center">
  <img src="Screenshots/08_Settings_and_Profile/settings_light_mode.png" width="49%" alt="Mainichi Notebook Light Mode" />
  <img src="Screenshots/08_Settings_and_Profile/settings_dark_mode.png" width="49%" alt="Mainichi Notebook Dark Mode" />
</p>

---

# Technical Overview

Mainichi Notebook is built using Apple's native development stack.

| Area                          | Technology                         |
| ----------------------------- | ---------------------------------- |
| Language                      | Swift                              |
| Primary UI                    | SwiftUI                            |
| Drawing                       | PencilKit                          |
| UIKit Integration             | UIViewRepresentable / UIScrollView |
| PDF Support                   | PDFKit                             |
| Speech                        | AVFoundation / AVSpeechSynthesizer |
| Notifications                 | UserNotifications                  |
| Persistence                   | JSON / local application storage   |
| Platform                      | iPadOS / iOS                       |
| External Runtime Dependencies | None                               |

The project intentionally avoids requiring a remote backend or third-party UI framework.

---

# Engineering Highlights

## 1. SwiftUI + UIKit Drawing Workspace

One of the more difficult parts of the project was combining:

* Apple Pencil drawing
* finger-based scrolling
* pinch-to-zoom
* page positioning
* SwiftUI layout

inside the same notebook workspace.

`PKCanvasView` works naturally for drawing, while UIKit's `UIScrollView` provides more direct control over zoom and gesture coordination.

The notebook therefore uses a custom `UIViewRepresentable` bridge around a UIKit scroll view.

The gesture coordinator uses `UIGestureRecognizerDelegate` to allow compatible gestures to operate together instead of forcing the entire editor into a SwiftUI-only gesture system.

This provides a practical separation:

```text
SwiftUI
   │
   ├── Notebook UI
   ├── Toolbars
   ├── Page navigation
   │
   ▼
UIViewRepresentable
   │
   ▼
UIScrollView
   │
   ├── Zoom / Pan
   │
   ▼
PKCanvasView
   │
   └── Apple Pencil Drawing
```

---

## 2. Local Notebook Persistence

Notebook content is persisted locally rather than depending on a server.

The storage layer is responsible for maintaining notebook metadata and page content inside the application's sandbox.

Native Codable types such as:

```swift
JSONEncoder
JSONDecoder
```

are used for structured data where appropriate.

This keeps the application usable without an account and makes the notebook data model easier to inspect and maintain.

---

## 3. Custom Spaced-Repetition Scheduler

The SRS implementation is intentionally separated from the quiz interface.

Given:

```text
Current card state
+ Review rating
+ Current time
```

the scheduler returns:

```text
Updated card state
+ Review record
+ Next due date
+ Updated interval
+ Updated ease factor
```

This makes scheduling logic independent from how a quiz screen happens to present the card.

Review history can also preserve information such as:

* previous interval
* next interval
* previous due date
* next due date
* previous ease factor
* updated ease factor
* selected rating

---

## 4. Vector-Based Writing Guides

Kana and Kanji stroke guides are represented using normalized coordinates rather than fixed-size bitmap images.

Coordinates can therefore be mapped into the current writing area and scaled for different screen sizes.

Conceptually:

```text
Normalized Point
(x: 0.0 ... 1.0, y: 0.0 ... 1.0)

        ↓ scale

Canvas Point
(x: screen width, y: screen height)
```

This allows character paths and guides to remain sharp when rendered at different sizes.

---

## 5. Reusable Visual Theme

Instead of scattering colors throughout individual screens, the application defines shared theme values for:

* backgrounds
* cards
* typography
* shadows
* Sakura accents
* green accents
* paper colors
* dark-mode surfaces
* spacing
* corner radii

This helps keep the different study modules visually consistent even though they serve very different purposes.

---

## 6. Service-Based Application State

Mainichi Notebook uses a pragmatic SwiftUI structure based around:

* Models
* Screens
* Reusable Components
* Storage Services
* Study Services
* Environment-injected application state

Services manage areas such as:

* SRS state
* daily summaries
* vocabulary
* study planning
* user profile
* application settings
* lecture storage

SwiftUI screens consume these services to render and update application state.

The project does **not** attempt to enforce a strict architectural pattern everywhere; the focus is on keeping feature logic and persistence reasonably separated as the application grows.

---

# Project Structure

A simplified view of the project:

```text
MainichiNotebook/
│
├── App/
│   ├── MainichiNotebookApp.swift
│   └── ContentView.swift
│
├── Theme/
│   ├── AppTheme.swift
│   └── AppThemeMode.swift
│
├── Models/
│   ├── VocabularyItem.swift
│   ├── FlashCardModels.swift
│   ├── LectureBook.swift
│   ├── PageAnnotation.swift
│   └── StudyProgress.swift
│
├── Services/
│   ├── SRS/
│   │   ├── SRSScheduler.swift
│   │   └── SRSService.swift
│   │
│   ├── LectureStorage/
│   │   └── LectureStorageService.swift
│   │
│   ├── PaperTemplates/
│   │   └── PaperTemplateRegistry.swift
│   │
│   ├── WritingPractice/
│   │   └── StrokePathRepository.swift
│   │
│   └── AppSettings/
│       ├── AppSettingsService.swift
│       └── LocalNotificationService.swift
│
├── Screens/
│   ├── HomeDashboardScreen.swift
│   ├── LecturesOverviewScreen.swift
│   ├── LectureBookEditorScreen.swift
│   ├── VocabularyLibraryScreen.swift
│   ├── WritingPracticeScreen.swift
│   ├── SimpleVocabularyPacksScreen.swift
│   ├── DailySummaryScreen.swift
│   ├── FlashCardsScreen.swift
│   └── Settings/
│       └── AppSettingsScreen.swift
│
├── Components/
│   ├── ZoomablePaperScrollView.swift
│   ├── PencilCanvasView.swift
│   ├── SidebarView.swift
│   └── PaperTemplates/
│
└── Resources / Study Data
```

The application is organized primarily by responsibility rather than forcing every feature into a single architectural abstraction.

---

# Getting Started

## Requirements

* A Mac capable of running Xcode 16 or later
* Xcode 16+
* iPadOS 16+ or iOS 16+
* iPad Simulator or physical Apple device
* Apple Pencil recommended for the intended notebook experience

The app is designed primarily around iPad-sized layouts.

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/Propose34/MainichiNotebook.git
cd MainichiNotebook
```

### 2. Open the Xcode project

```bash
open MainichiNotebook.xcodeproj
```

### 3. Select a target

For the intended experience, choose an iPad simulator such as:

```text
iPad Pro
iPad Air
```

A physical iPad with Apple Pencil can also be used.

### 4. Build and run

Press:

```text
⌘ + R
```

or use Xcode's **Run** button.

No third-party package installation is required.

---

# Privacy & Data

Mainichi Notebook was designed as a local-first personal study application.

### Local storage

Study-related data is stored inside the application's sandbox, including data such as:

* notebook metadata
* drawings
* study progress
* flashcard state
* custom vocabulary
* preferences
* daily summaries

### No account required

The application does not require users to create a Mainichi Notebook account.

### No external analytics SDK

The project does not include third-party analytics or advertising SDKs such as Firebase Analytics.

### Native system services

Features such as Japanese pronunciation and study reminders use native Apple frameworks.

### User-controlled export

Content only leaves the app when the user intentionally performs actions such as exporting or sharing notebook pages through the system Share Sheet.

---

# Development Approach

Mainichi Notebook is both a personal product-design project and an experiment in modern AI-assisted software development.

### Product & design

The following areas were designed and directed by me:

* product concept
* feature scope
* information architecture
* UX flow
* visual direction
* screen layouts
* interaction ideas
* Japanese study workflow
* feature prioritization
* iterative product decisions

### AI-assisted implementation

AI coding tools were used extensively during implementation.

Rather than treating generated code as the product itself, development was driven through repeated cycles of:

```text
Idea
  ↓
Product / UX specification
  ↓
AI-assisted implementation
  ↓
Run & inspect
  ↓
Debug / adjust behavior
  ↓
UI iteration
  ↓
Integration
```

This project represents my approach to using AI as a development tool while retaining ownership of the product direction, design decisions, feature behavior, and final user experience.

---

# Project Status

Mainichi Notebook is currently a **personal / portfolio project**.

The primary goal of the project was to explore the complete process of designing a focused application around a real user workflow — from product concept and interface design to native iOS implementation and iteration.

The current version is optimized primarily for iPad usage.

Potential areas for future development include:

* deeper notebook organization
* improved adaptive layouts
* stronger automated testing
* accessibility improvements
* richer handwriting feedback
* optional cross-device synchronization
* additional Japanese study datasets

---

# License

This project is open source under the **MIT License**.

See [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>毎日、少しずつ。</b><br/>
  A little every day. 🌸
</p>

<p align="center">
  Mainichi Notebook (毎日ノート)
</p>
