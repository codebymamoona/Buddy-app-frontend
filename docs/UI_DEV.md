\# UI development without the backend



Android emulator or phone only. The floating overlay plugin does not run on desktop or web.



Toolchain: Flutter Flutter 3.47.6 • channel stable • https://github.com/flutter/flutter.git

Framework • revision 5fc346839b (11 days ago) • 2026-09-30 15:02:49 -0700

Engine • hash b8c8d3d8d5d0095127057f8a29ca8cc53da2167c (revision 692136cb65) (12 days ago) • 2026-09-30 00:56:59.000Z

Tools • Dart 3.13.5 • DevTools 2.60.0, Dart <paste>. Build warnings about the Android Gradle Plugin version or "SDK XML version" are known tooling notices, not errors.



\## One-time setup

The Android build needs a google-services.json file even though mock mode never uses Firebase. If you do not have the real one, copy the placeholder:



&#x20;   Copy-Item android\\app\\google-services.mock.json android\\app\\google-services.json



Never commit android/app/google-services.json, and never commit keys, .env files or service-account files.



\## Run (quote the flag)



&#x20;   flutter run "--dart-define=USE\_MOCK=true"



A MOCK ribbon appears in the top-right corner. No ribbon means the flag did not apply. Flags are fixed when the app starts, so stop and re-run after changing them (hot reload does not apply them).



| Flag | Effect |

|---|---|

| MOCK\_DELAY\_MS=3000 | Slower responses, to tune loading animations |

| MOCK\_EMPTY=audit | Empty state. Names: chat, pending, audit, decision, cap |

| MOCK\_FAIL=audit,pending | Error state. Names: chat, pending, audit, decision, cap, friend |

| MOCK\_START=login | Start on the login screen. Any email signs in; an email containing "fail" shows an error. Sign up works the same way. |



Combine flags by repeating them: flutter run "--dart-define=USE\_MOCK=true" "--dart-define=MOCK\_DELAY\_MS=3000"



Chat in mock mode is scripted. It only answers: "I am hungry" then "yes", "Book a flight to Dubai", "Buy a blue T-shirt", /long (long reply) and /error (network error).



\## What is not real in mock mode

\- Login and signup: Firebase is skipped entirely.

\- AI replies: scripted, not the real assistant.

\- Friend profile saving: the backend endpoint is not built. Against the real server the save shows "Friend profiles aren't available on the server yet."

\- Push notifications: not built.



\## Rules

\- All network calls go through lib/services/api\_service.dart. A direct http call bypasses the mock and breaks everyone's build.

\- Changes under lib/services/ and lib/config/ need review from the backend owner. They define the contract with the server, and lib/services/mock\_backend.dart must change with every backend response change, or the UI passes here and breaks against the real server.

\- Before merging any UI branch, run it once against the real backend.

\- Screens, widgets, theme and assets belong to the UI team.

