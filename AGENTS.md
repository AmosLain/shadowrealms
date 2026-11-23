# Shadow Realms

Build a cinematic, original dark-fantasy belt-scroller for Android landscape. Keep the three heroes, six gates, original art and checkpoint compatibility playable at every checkpoint. Use Godot 4.7.2 and GDScript.

## Ownership

The Game Director selects the highest-impact reproducible problem from docs/ROADMAP.md, defines its player-visible acceptance condition and assigns files. Use gameplay_engineer for combat and encounters, visual_director for presentation and qa_android for reproduction, regression coverage and Android checks. Read-only analysis can overlap. Integrate production changes sequentially or use isolated worktrees.

## Architecture

The entry scene is scenes/Keep.tscn. scripts/keep.gd owns the road, progression and encounters. fighter.gd steps movement, attacks and AI. rules.gd owns move data and hero identities. rig.gd renders atlas poses. interface.gd and touch.gd handle screen-space UI and finger ownership. Keep snake_case names and existing scene paths, signals, input actions and save keys. Prefer existing systems over new dependencies. Use original or compatible licensed assets and record any required attribution.

## Validation

Run from the repository root with the matching Godot executable on PATH. Import first. Supply a writable build directory and the configured Android SDK, JDK and debug keystore when exporting.

~~~sh
godot --headless --editor --import
godot --headless --fixed-fps 60 -s res://tests/checks.gd
godot --headless --fixed-fps 60 -s res://tests/playthrough.gd -- warden
godot --headless --export-debug Android build/ShadowRealms.apk
godot --headless --export-release "Windows Desktop" build/ShadowRealms.exe
~~~

Run each behavior suite in tests with the same flags as checks.gd. Repeat playthrough.gd for seer and swift. Run capture.gd with a graphical renderer and an existing output directory after --. Read logs for script errors as well as exit status. Synthetic touch and a signed APK are separate from testing on an Android device.

## Checkpoint and continuation

Read docs/PROGRESS.md and docs/ROADMAP.md before selecting work. Reproduce the issue, implement one bounded improvement and add a failing-before regression when behavior changes. Inspect a normal gameplay path, capture visual changes, run the affected tests and all hero campaigns after combat changes. Record evidence and remaining uncertainty. Commit a focused checkpoint and update the backlog. Preserve the source worktree, save compatibility and licenses. Keep generated builds and signing material outside Git. Use a local checkpoint branch. Release publication requires separate authorization.
