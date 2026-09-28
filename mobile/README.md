# mobile/ — PashuSetu Android app (Flutter)

- One app with role-based modes: farmer, pashu sevak, vet, lab, district officer.
- `lib/core/theme/` holds the design tokens, typography and theme (spec Section 9). Screens never pick their own colours or fonts.
- Fonts are bundled in `assets/fonts/` (Mukta, Anek Devanagari, both OFL) so the app works offline.
- `assets/shared/` is a **copy** of the repo's `shared/` folder, made by `make sync-shared`. Don't edit it here.
- Features go in `lib/features/<name>/` and reusable design-system widgets in `lib/widgets/` (Phase 3 onwards).

```bash
make sync-shared         # from repo root, after any change in shared/
cd mobile
flutter run              # phone over USB, or an emulator
flutter analyze && flutter test
```

Emulator talks to the laptop backend at `http://10.0.2.2:8000`. A real phone needs the laptop's LAN IP.
