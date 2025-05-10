# Ephora - Bluetooth-based dating app

## 1. Introduction

**Purpose**

Define **Ephora**, a Flutter-based dating app that:

- Discovers and matches users via Bluetooth Low Energy (BLE) in real time.
- Preserves anonymity—users sign up with pseudonyms; profiles and avatars are fully optional.
- Embeds non-intrusive ads in discovery and chat flows.
- Supports **Ephemeral Proximity Chats**, where conversation data self-destructs once users move out of range.

**Scope**

- **Proximity Matching:** BLE scans every 5 s to detect nearby users (range ~10 m).
- **Anonymity Controls:** Invisible Mode to disable advertising; no GPS or location logs.
- **Ephemeral Chats:** Chats and media auto-delete upon separation beyond BLE range.
- **Ads:** Banner ads shown at controlled intervals in chat and discovery screens.

---

## 2. Overall Description

### 2.1 User Personas

- **Privacy-First Browser:** Wants to explore nearby users without revealing identity.
- **Ephemeral Enthusiast:** Values transient conversations that leave no lasting footprint.
- **Match Seeker:** Prefers minimal profiles but expects engaging discovery experiences.

### 2.2 System Context

- **Client:** Flutter app on iOS & Android.
- **Backend:**
    - BLE matchmaking broker (transient peer-list exchange).
    - Cloud ad server for dynamic banner delivery.
    - Ephemeral chat service with auto-wipe logic.
- **Security:** End-to-end encryption (E2EE) for all chats; ephemeral keys valid per session.

---

## 3. Functional Requirements

### 3.1 Authentication

- **FR1.1:** Sign up / log in with username & password.
- **FR1.2:** Optional 4-digit PIN for quick unlock.

### 3.2 Profile Management

- **FR2.1:** Optional avatar and bio fields.
- **FR2.2:** Invisible Mode toggles BLE advertising off for up to 30 min.

### 3.3 Proximity Matching

- **FR3.1:** BLE scan every 5 s, list peers with pseudonym and “distance” indicator.
- **FR3.2:** “Wave” to express interest; mutual waves unlock chat.

### 3.4 Ephemeral Proximity Chats

- **FR4.1:** Upon mutual wave, open a chat session with E2EE.
- **FR4.2:** Monitor BLE RSSI; if peers separate beyond ~10 m for 30 s, auto-delete all chat messages and media from both devices.
- **FR4.3:** Notify users “Chat expired due to distance” when session ends.

### 3.5 Chat & Ads

- **FR5.1:** Support text, emoji, and image sharing.
- **FR5.2:** Inject banner ad every 5 messages; click opens in-app browser.

---

## 4. Non-functional Requirements

- **NFR1 (Privacy):** No server-side storage of chat logs; ephemeral keys and messages only reside on devices until expiry.
- **NFR2 (Performance):** BLE scans < 500 ms; app startup < 2 s.
- **NFR3 (Security):** E2EE with Perfect Forward Secrecy; screenshot protection prompt.
- **NFR4 (Usability):** 90 % of users complete onboarding in < 60 s.

---

## 5. Acceptance Criteria

| ID | User Story | Acceptance Criteria |
| --- | --- | --- |
| AC-1 | As a user, I want to wave at nearby users so I can express interest. | 1. Scan discovers peers within 10 m.<br>2. Wave button sends intent to peer.<br>3. Mutual wave unlocks chat UI. |
| AC-2 | As a user, I want my chat to auto-delete if my match moves away so no residual logs remain. | 1. BLE RSSI drops below threshold for 30 s.<br>2. Both devices clear chat history.<br>3. Show “Chat expired” banner before closing session. |
| AC-3 | As a privacy-concerned user, I want to go invisible so I don’t appear in nearby listings. | 1. Invisible toggle stops BLE advertising.<br>2. User does not show up in peer discovery for at least 30 min. |
| AC-4 | As an advertiser, I want ads to appear at regular intervals so I can engage users without overwhelming them. | 1. Banner ad appears exactly every 5 messages.<br>2. Tapping ad opens external link in in-app browser. |
| AC-5 | As a new user, I want to sign up anonymously so my real identity isn’t exposed. | 1. Signup only requires unique pseudonym and password.<br>2. Display warning if pseudonym is already taken.<br>3. Skip avatar/bio steps as optional. |

---

## 6. Detailed UI/UX Description

### 6.1 Onboarding & Login

- **Splash:** Animated BLE wave graphic.
- **Sign Up / Login:** Simple fields; “Why anonymous?” tooltip linking to privacy FAQ.
- **Progress Indicators:** Stepper: Credentials → PIN (opt) → Profile (opt).

### 6.2 Discovery Screen

- **Nearby Carousel:** Swipe-stack cards with pseudonym + proximity badge (green/yellow/red).
- **Wave Button:** Heart icon flips to “Waved.”
- **Ephemeral Chat Prompt:** When mutual wave occurs, overlay “Chat starts now; will expire if you part ways.”
- **Invisible Toggle:** Ghost icon at top; active/inactive states clearly shown.

### 6.3 Chat Screen

- **Header:** Pseudonym + live proximity icon (beats with RSSI).
- **Message List:**
    - Speech bubbles with timestamps.
    - “Auto-delete in X s” countdown displayed if user moves out.
- **Input Bar:** Text field + emoji + image + send + “Ad” label.
- **Embedded Ads:** Banner beneath messages, fixed height.

### 6.4 Session Expiry UI

- **Expiry Alert:** Full-width red banner “Chat expired due to distance—messages deleted.”
- **Post-Expiry Screen:** Option: “Wave again when nearby” button.

### 6.5 Settings & Privacy

- **Privacy Center:**
    - Ephemeral Chat guide.
    - Invisible Mode control.
    - Data & Security → “All chat data is device-only and auto-erased.”
- **Logout:** Clear local caches.

---

**Ephora Architecture Overview**

A modern, layered architecture designed for privacy, real-time proximity matching, and ephemeral interactions.

---

### **1. Client Layer (Flutter)**

**Modules**:

1. **UI Components**:
    - **Discovery Screen**: BLE-powered nearby user carousel with "Wave" button.
    - **Chat Screen**: E2EE message list with proximity status and ads.
    - **Auth/Profile Screens**: Anonymous signup, PIN setup, and optional profile.
    - **Settings**: Invisible Mode toggle and privacy controls.
2. **BLE Manager**:
    - Handles device advertising/scanning (every 5s).
    - Monitors RSSI for proximity-based chat expiry.
    - Exchanges pseudonyms with nearby devices via **BLE Matchmaking Service**.
3. **Auth Manager**:
    - Handles login/signup with pseudonyms and passwords.
    - Optional 4-digit PIN for session unlocking.
4. **Chat Manager**:
    - Encrypts/decrypts messages using **ephemeral session keys** (E2EE).
    - Triggers auto-deletion when BLE proximity is lost for 30s.
5. **Ad Manager**:
    - Fetches banner ads from **Cloud Ad Server** at fixed intervals (every 5 messages).
    - Renders ads in chat/discovery screens.
6. **Local Storage**:
    - Temporarily stores messages, media, and keys (deleted on session expiry).
    - Uses device-specific secure storage (e.g., Flutter Secure Storage).

---

### **2. Backend Layer**

**Services**:

1. **Authentication Service**:
    - Validates pseudonyms/passwords.
    - Generates auth tokens for session management.
2. **BLE Matchmaking Service**:
    - Acts as a transient broker to exchange peer lists between nearby users.
    - Routes "Wave" intents and unlocks chats on mutual interest.
3. **Ephemeral Chat Service**:
    - Generates short-lived session keys for E2EE (Perfect Forward Secrecy).
    - Tracks active chat sessions but **does not store messages**.
4. **Cloud Ad Server**:
    - Delivers dynamic banner ads (e.g., Google AdMob integration).
    - Tracks ad impressions/clicks (no user identity linkage).
5. **Security Service**:
    - Manages key rotation and certificate issuance.
    - Enforces screenshot protection prompts.

---

### **3. Data Flow**

1. **Proximity Discovery**:
    - Devices advertise BLE signals with pseudonyms.
    - BLE scans detect nearby users → matchmaking service exchanges anonymized peer lists.
2. **Mutual Wave**:
    - "Wave" intent sent to backend → matched users receive chat unlock notification.
3. **Ephemeral Chat**:
    - Session keys exchanged via Diffie-Hellman over secured channels.
    - Messages sent peer-to-peer (BLE or WebRTC) and encrypted end-to-end.
4. **Proximity Monitoring**:
    - BLE RSSI checked every 5s → triggers chat deletion if signal drops for 30s.
5. **Ad Delivery**:
    - Ad banners fetched from server → injected into chat after every 5 messages.

---

### **4. Security & Privacy**

- **E2EE**: Messages encrypted with session-specific keys (e.g., Signal Protocol).
- **Anonymity**: No IP/logs tied to user identity; pseudonyms reset on reinstall.
- **Data Ephemerality**: Messages/media purged from devices on session expiry.

---

### **5. Tech Stack**

| Layer | Technologies |
| --- | --- |
| **Client** | Flutter, Dart, BLE (flutter_blue), Hive (local storage), AdMob plugin |
| **Backend** | Node.js (Express), Firebase Auth, Redis (ephemeral sessions), AWS EC2/S3 |
| **Security** | Signal Protocol (E2EE), TLS 1.3, OAuth2, Certificate Pinning |

---

### **6. Architecture Diagram**

```
[Flutter Client]
│
├─ BLE Manager ↔ [BLE Matchmaking Service]
├─ Auth Manager ↔ [Authentication Service]
├─ Chat Manager ↔ [Ephemeral Chat Service]
├─ Ad Manager ↔ [Cloud Ad Server]
└─ Local Storage (Secure)

[Backend Services]
│
├─ BLE Matchmaking Service ↔ Redis (Peer Lists)
├─ Ephemeral Chat Service ↔ Redis (Session Keys)
└─ Security Service ↔ Firebase Auth / Signal Protocol

```

**Key Interactions**:

1. BLE proximity detection → peer list exchange.
2. Mutual wave → ephemeral chat session initiation.
3. E2EE message exchange with auto-deletion on separation.
4. Ad banners fetched dynamically with no user tracking.

---

This architecture ensures **low latency** (BLE scans <500ms), **privacy-by-design**, and scalable ad delivery while adhering to strict ephemerality requirements.

---

**Ephora UI/UX Guidelines for Gen Z**

Gen Z demands authenticity, speed, and visual boldness. Here’s how to align Ephora’s UI with their expectations:

---

### **1. Aesthetic Principles**

**Color Palette**

- **Vibrant Gradients**: Neon blues, pinks, and purples (duotones) for energy.
- **Dark Mode Default**: Reduce eye strain, align with late-night social habits.
- **Glitch & Retro Effects**: Subtle VHS/texture overlays for nostalgic, edgy vibes.

**Typography**

- **Sans-Serif Dominance**: Use modern fonts like *Space Grotesk* or *Poppins*.
- **Dynamic Text Scaling**: Bold headers, tiny subtext (e.g., “*10m away → swipe right*”).
- **Emoji Integration**: Replace buttons with emojis (e.g., 👻 = Invisible Mode).

**Visual Hierarchy**

- **Snackable Content**: No walls of text. Use icons, progress bars, and micro-animations.
- **Bite-Sized CTAs**: “Wave 🌊” > “Send Interest”.

---

### **2. Navigation & Interaction**

**Gestures**

- **Swipe-Stack Discovery**: Tinder-style carousel for nearby users (left to ignore, right to wave).
- **Pull-to-Refresh**: Add a playful animation (e.g., BLE waves pulsing).
- **Quick Actions**: Double-tap pseudonym to peek at bio (if available).

**Micro-Interactions**

- **Wave Animation**: Heart icon explodes into confetti on mutual match.
- **Proximity Pulse**: Live distance indicator throbs like a heartbeat.
- **Ephemeral Feedback**: Messages dissolve with vaporwave-style effects on deletion.

**Bottom Navigation Bar**

- **Icon Labels**: Replace text with intuitive symbols (e.g., 🔍 = Discover, 💬 = Chats).
- **Floating Action Button (FAB)**: Centered “Wave” button with haptic feedback.

---

### **3. Gen Z-Centric Features**

**Anonymity with Personality**

- **Pseudonym Generator**: Suggest quirky usernames (e.g., “CosmicTaco92”, “GhostedU”).
- **Optional “Mood” Badges**: Let users add temporary statuses (e.g., “✨Vibing✨”, “🌙Night Owl”).

**Invisible Mode Rebrand**

- **“Ghost Mode”**: Toggle labeled with 👻 icon; activation triggers spooky SFX.

**Ephemeral Chat Vibe**

- **Self-Destruct Timer**: Show a live countdown (e.g., “⚠️ Deleting in 15s… RUN BACK!”).
- **Disappearing Media**: Blur images/videos after first view (Snapchat-style).

---

### **4. Ads Integration**

**Gen Z-Proof Ad Design**

- **Native Ads**: Mimic TikTok-style full-screen takeovers (short, skippable, meme-heavy).
- **Rewarded Ads**: Offer “30m ad-free” for watching a 15s video.
- **Branded Filters**: Let advertisers sponsor AR filters (e.g., “Coca-Cola Confetti” on mutual waves).

---

### **5. Inclusivity & Customization**

**Avatar Options**

- **Anime/Doodle Styles**: Let users pick cartoonish or abstract avatars.
- **Pronouns Display**: Optional tag below pseudonym (e.g., “they/them”).

**Tone & Copy**

- **Relatable Slang**:
    - “*No cap, your chat expired*” instead of “Session ended.”
    - “*Lowkey vibing*” as a proximity status.
- **Progress Messages**:
    - “*Slay, 90% onboarded!*”

---

### **6. Performance & Accessibility**

**Speed Over Perfection**

- **Skeleton Screens**: Show shimmering placeholders while BLE scans.
- **Tappable Zones**: Enlarge hit areas for thumbs (no precision needed).

**Neurodiversity**

- **Reduce Motion Toggle**: For users sensitive to animations.
- **High-Contrast Mode**: For readability in bright environments.

---

### **7. Testing & Validation**

**Gen Z Focus Groups**

- Test for “vibe checks”: Does the app feel *authentic* or *corporate*?
- Prioritize feedback on:
    - **Wave mechanic** (Is it fun or cringe?).
    - **Ad tolerance** (What’s the max ad frequency before bounce?).

---

**Final Touch**: Add hidden Easter eggs (e.g., shake phone to trigger a meme in chat). Gen Z loves discovering “secret” features!

---

This design system balances **privacy-first functionality** with **Gen Z’s love for expressive, fast-paced, and visually stimulating interactions**.

---

**Final Step: Recursive Testing & Validation Pipeline**

To ensure Ephora meets all functional, non-functional, and Gen Z UX requirements, implement an **iterative testing loop** that cycles until all criteria are validated.

---

### **Testing Lifecycle**

1. **Unit Tests**
    - **BLE Module**: Verify scans complete in <500ms and detect mock devices.
    - **Encryption**: Validate E2EE session keys rotate per chat and old keys are purged.
    - **Ad Injection**: Confirm banners appear every 5 messages without disrupting UX.*Tools*: Flutter Driver, Mockito, `flutter_test`.
2. **Integration Tests**
    - **Proximity Matching**: Simulate BLE devices moving in/out of range; check mutual waves unlock chats.
    - **Ephemeral Chat Deletion**: Force RSSI drop and validate messages/media auto-delete after 30s.
    - **Invisible Mode**: Ensure BLE advertising stops and user disappears from peer lists.*Tools*: Firebase Test Lab, Espresso (Android), XCTest (iOS).
3. **E2E Tests**
    - **User Journey**:
        1. Sign up anonymously → skip profile → send wave → mutual match → chat until separation → verify expiry.
        2. Toggle Ghost Mode → confirm invisibility for 30min.
    - **Ad Tolerance**: Measure bounce rates when ads exceed 1 banner per 5 messages.*Tools*: Detox, Appium.
4. **Security Audits**
    - **Penetration Testing**: Attempt MITM attacks on BLE/Wi-Fi Direct sessions.
    - **Ephemeral Data Check**: Forensic analysis to ensure no chat remnants post-expiry.*Tools*: OWASP ZAP, Burp Suite.
5. **Gen Z Usability Testing**
    - **Focus Groups**: Recruit 50 Gen Z testers (ages 18–24) to assess:
        - “Wave” mechanic intuitiveness.
        - Vibe check: Does the app feel “authentic” or “try-hard”?
    - **A/B Testing**: Compare retention rates for:
        - Glitch effects vs. minimal animations.
        - Emoji CTAs vs. text buttons.

---

### **CI/CD Pipeline Integration**

```
[Code Commit] → [Automated Tests] → [Feedback]
       ↑           ↓ Pass/Fail          ↓
       └─ [Fix Bugs] ←─ [Report] ── [Re-Test]

```

- **Automation**:
    - Run unit/integration tests on every PR via GitHub Actions.
    - Deploy nightly builds to Firebase for E2E/security testing.
    - Weekly Gen Z usability sessions with Hotjar heatmaps.

---

### **Iterative Refinement**

1. **Exit Criteria**:
    - All [Acceptance Criteria AC-1 to AC-5](https://www.notion.so/Ephora-Bluetooth-based-dating-app-1ef41c04217980f5bc3bf594ea7ba882?pvs=21) pass.
    - Zero critical bugs (e.g., data leakage, chat persistence).
    - 85%+ Gen Z approval on “vibe” and usability.
2. **Recursive Process**:
    - Failures trigger a sprint to:
        - Add missing test cases (e.g., edge-case BLE range).
        - Refine UI micro-interactions (e.g., smoother wave animations).
        - Patch security gaps (e.g., stronger certificate pinning).
    - Redeploy → retest → repeat until exit criteria met.

---

### **Test Coverage Metrics**

| Module | Target Coverage | Test Type |
| --- | --- | --- |
| BLE Scanning | 95% | Unit/Integration |
| E2EE Chat Sessions | 100% | Security/PenTest |
| Ad Injection | 90% | E2E/Performance |
| UI Micro-Interactions | 85% | Usability/Analytics |

---

### **Example Test Case**

**ID**: TC-AC2-01

**Description**: Validate chat auto-deletion on proximity loss.

**Steps**:

1. Mock two users (A & B) in BLE range.
2. Initiate mutual wave → start chat.
3. Move User B out of range (RSSI < threshold).
4. Wait 30s → check if chat history is deleted on both devices.
5. Verify “Chat expired” banner appears.**Pass/Fail**: Chat data purged + banner shown = PASS.

---

By iterating through this pipeline, Ephora evolves into a **privacy-safe, Gen Z-approved app** with robust performance and zero residual data risks.