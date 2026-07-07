# Toona Matrix Client — Missing Features

**Date:** 2026-07-07  
**Prioritized gap analysis with Matrix spec references**

---

## Critical (Blocks Real-World Use)

| # | Feature | Spec Reference | Impact | Effort | Dependencies |
|---|---------|---------------|--------|--------|--------------|
| 1 | **E2EE Decryption** | [MEGOLM](https://matrix.org/docs/spec/client_server/latest#e2ee) | Cannot read encrypted messages. Most Matrix rooms are encrypted. | XL | Olm/Megolm library, key verification, session management |
| 2 | **Push Notification Delivery** | [Push Gateway](https://matrix.org/docs/spec/client_server/latest#push-gateway-api) | No background notifications. Users miss messages when app is closed. | L | Huawei Push Kit SDK, push gateway registration |
| 3 | **SSO/OAuth Authentication** | [SSO](https://matrix.org/docs/spec/client_server/latest#login) | Cannot use corporate/SSO identity providers. Required by many organizations. | M | OAuth2 flow, webview for auth |
| 4 | **Image Viewer** | N/A (UX) | Tapping images shows a toast. No way to view images properly. | M | Fullscreen modal, zoom, gallery swipe |
| 5 | **File Preview/Download** | N/A (UX) | File messages are display-only. Cannot download or open files. | M | File download, intent to open with external apps |

---

## High Priority (Expected by Users)

| # | Feature | Spec Reference | Impact | Effort | Dependencies |
|---|---------|---------------|--------|--------|--------------|
| 6 | **Thread View** | [Threads](https://matrix.org/docs/spec/client_server/latest#threads) | No threaded conversations. Cannot follow reply chains. | L | Thread state, UI, API integration |
| 7 | **Reaction Picker + Sender** | [Annotations](https://matrix.org/docs/spec/client_server/latest#annotations) | Cannot react to messages. Missing core social feature. | M | Emoji picker, annotation API |
| 8 | **Sticker Picker + Sender** | [Stickers](https://matrix.org/docs/spec/client_server/latest#stickers) | Can receive stickers but not send them. | M | Sticker packs, send UI |
| 9 | **Room Settings Page** | N/A (UX) | Cannot change room name, topic, avatar, or manage members. | L | Room state API, member management UI |
| 10 | **User Profile Page** | N/A (UX) | Cannot view other users' profiles or initiate DMs from profile. | M | Profile API, user action sheet |
| 11 | **Notification Settings** | [Push Rules](https://matrix.org/docs/spec/client_server/latest#push-rules) | Push rules exist but no per-room or global notification config UI. | M | Settings UI, push rule management |
| 12 | **Invite Management Page** | N/A (UX) | Invites are counted but not shown/listed for acceptance. | M | Invite list, accept/decline UI |
| 13 | **Server-Side Message Search** | [Search](https://matrix.org/docs/spec/client_server/latest#search) | Only local DB filtering. No server-side full-text search. | M | Search API, result display |
| 14 | **Backfill/Pagination** | [Messages](https://matrix.org/docs/spec/client_server/latest#get-rooms-roomid-messages) | Sync returns `limited` flag but messages are not backfilled. | M | prev_batch token, pagination UI |
| 15 | **Message Forwarding** | N/A (UX) | Cannot forward messages to other rooms. | S | Forward API, room selector |
| 16 | **Message Pinning** | N/A (UX) | Cannot pin important messages. | S | Pin state, pinned messages UI |
| 17 | **Notification Settings (Global)** | N/A (UX) | No global notification preferences (sound, vibration, etc.). | M | Settings UI |

---

## Medium Priority (Feature Completeness)

| # | Feature | Spec Reference | Impact | Effort | Dependencies |
|---|---------|---------------|--------|--------|--------------|
| 18 | **Voice/Video Call UI** | [VoIP](https://matrix.org/docs/spec/client_server/latest#voip) | Calls are stubs. Only TURN credentials fetched. | XL | WebRTC, call events, call UI |
| 19 | **Message Reporting/Abuse** | N/A (UX) | Cannot report abusive messages. | S | Report API |
| 20 | **View Message Source (JSON)** | N/A (UX) | Cannot view raw event JSON for debugging. | S | Event display modal |
| 21 | **Room Upgrade** | [Room Version](https://matrix.org/docs/spec/client_server/latest#room-versioning) | Cannot upgrade room versions. | M | Upgrade API, migration UI |
| 22 | **Room History Visibility** | [History Visibility](https://matrix.org/docs/spec/client_server/latest#room-history-visibility) | Cannot change who can see room history. | M | State event, settings UI |
| 23 | **Password Change** | [Account](https://matrix.org/docs/spec/client_server/latest#change-password) | Cannot change account password. | S | UIA flow |
| 24 | **Account Deactivation** | [Account](https://matrix.org/docs/spec/client_server/latest#account-deactivation) | Cannot deactivate account. | S | UIA flow |
| 25 | **3PID Lookups** | [Identity](https://matrix.org/docs/spec/identity_service/latest) | Cannot invite by email or phone. | M | Identity server integration |
| 26 | **Rich Text Formatting** | N/A (UX) | No markdown/rich text in composer. | M | Markdown parser, toolbar |
| 27 | **Link Previews in Composer** | N/A (UX) | URL previews not shown while composing. | S | Preview API integration |
| 28 | **Read Receipt Privacy** | [Receipts](https://matrix.org/docs/spec/client_server/latest#read-receipts) | No option to hide read receipts. | S | Privacy setting |

---

## Low Priority (Nice to Have)

| # | Feature | Spec Reference | Impact | Effort | Dependencies |
|---|---------|---------------|--------|--------|--------------|
| 29 | **Video Message Recording** | N/A (UX) | Cannot record and send video messages. | L | Camera, video encoding |
| 30 | **Location Sharing** | N/A (UX) | Cannot share location. | M | Location API, map UI |
| 31 | **Custom Emoji** | N/A (UX) | No custom emoji support. | M | Emoji picker, custom packs |
| 32 | **Key Verification (SAS/QR)** | [Verification](https://matrix.org/docs/spec/client_server/latest#key-verification) | Cannot verify device keys. | L | Verification flow UI |
| 33 | **Cross-Signing** | [Cross-signing](https://matrix.org/docs/spec/client_server/latest#cross-signing) | No cross-signing support. | XL | Key management, verification |
| 34 | **Key Import/Export** | [Key Backup](https://matrix.org/docs/spec/client_server/latest#key-Backup) | Cannot export or import E2EE keys. | M | Backup API, file I/O |
| 35 | **Device Verification** | N/A (UX) | Cannot verify other devices. | M | Verification UI |
| 36 | **Custom Room State** | N/A (UX) | Cannot set custom room state events. | S | State editor |
| 37 | **Room Access Rules** | N/A (UX) | Cannot configure room access (public/private/restricted). | M | State events, settings UI |
| 38 | **Guest Access** | [Guest Access](https://matrix.org/docs/spec/client_server/latest#guest-access) | No guest user support. | M | Guest auth, limited access |

---

## Summary by Effort

| Effort | Count | Features |
|--------|-------|----------|
| **S** (1-2 days) | 12 | Message forwarding, pinning, reporting, source view, password change, deactivation, rich text, link previews, read receipts privacy, custom room state, room access rules, device verification |
| **M** (3-5 days) | 14 | SSO, image viewer, file preview, reactions, stickers, user profiles, notifications, invites, search, backfill, history visibility, 3PID, location, key import/export |
| **L** (1-2 weeks) | 8 | Push delivery, threads, room settings, VoIP calls, video messages, key verification, cross-signing, guest access |
| **XL** (2+ weeks) | 3 | E2EE decryption, cross-signing (full), VoIP (full) |

---

## Recommended Implementation Order

### Phase 1: Basic Usability (2-3 weeks)
1. Image viewer (M)
2. File preview/download (M)
3. Push notification delivery (L)
4. Server-side message search (M)

### Phase 2: Core Features (2-3 weeks)
5. Room settings page (L)
6. Reaction picker + sender (M)
7. Thread view (L)
8. Invite management page (M)

### Phase 3: Authentication & Security (2-3 weeks)
9. SSO/OAuth authentication (M)
10. E2EE decryption (XL)
11. Key verification (L)
12. Password change (S)

### Phase 4: Polish (1-2 weeks)
13. Message forwarding (S)
14. Message pinning (S)
15. User profile page (M)
16. Notification settings (M)
17. Backfill/pagination (M)
