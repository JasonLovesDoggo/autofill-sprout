# AutoFill Sprout 🌱

A tiny native macOS app for poking Apple's password AutoFill APIs. Three buttons check the identity store, request activation, and publish one fake login. Swift + AppKit; no vault access, network calls, or dependencies.

<img width="677" height="363" alt="Screenshot 2026-10-01 at 1 15 13 AM" src="https://github.com/user-attachments/assets/05f4a3f4-1269-49fc-883d-a401303ba3ec" />


```text
ad-hoc signed build
├─ sandbox only        → opens; AutoFill identity write is rejected
└─ + AutoFill entitlement → AMFI rejects launch on the tested Mac
```



This is a diagnostic toy, not a signing bypass. On macOS 27.0.1 with SIP enabled, adding the entitlement alone caused AMFI to report “adhoc signed but contains restricted entitlements.” `codesign --verify` still passed. A disabled store alone doesn't prove a signing problem.

## Try it

Requires macOS 15+ and Apple's Command Line Tools (`xcode-select --install`).

```sh
git clone git@github.com:JasonLovesDoggo/autofill-sprout.git
cd autofill-sprout
./build.sh
open "build/AutoFill Sprout.app"
```

`./build.sh --autofill` rebuilds both the host and extension claiming the restricted capability. It does **not** obtain a provisioning profile or change SIP, AMFI, or Gatekeeper settings; an ad-hoc build can be killed before its window appears. Run `./build.sh` again to restore the ordinary build.

The only credential is `synthetic-user` / `synthetic-password` for `http://localhost:9876`. If accepted by macOS, “Publish test identity” adds that synthetic identity to this app's AutoFill store. The bundled provider returns only that fake credential.

MIT licensed.
