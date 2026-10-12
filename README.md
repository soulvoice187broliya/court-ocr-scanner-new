# Court OCR Scanner

Flutter Android project for scanning court documents, reviewing OCR results, and exporting an Excel register.

## Build
GitHub Actions automatically builds the release APK on pushes to `main` or via **Actions → Build Court OCR Scanner APK → Run workflow**. Download `Court-OCR-Scanner-APK` from the run's Artifacts section.

## Required repository structure
`pubspec.yaml`, `lib/main.dart`, `.github/workflows/build-apk.yml`.

## Features in this starter
- On-device Latin-script OCR from camera/gallery.
- Editable preview for mapped columns A, B, C, D, E, F, G, H, I, J, K, P, Q, R, T, W, AE, AF, AM.
- Load an existing `.xlsx` workbook and append to the first/`Visible Data` sheet, leaving other columns in place.
- W assignee options saved in app settings and can be added, edited, or removed.
- AE, AF, AM dropdown options.
- Excel export via Android share sheet.
- Date/month formatting helpers.

## Important limitations to verify before official use
- OCR field extraction uses heuristics; it is not a certified legal-document parser. Always review every field before saving.
- The workbook must have a compatible first worksheet; protect/backup the original register before testing.
- Registration numbering and daily serial behavior should be validated against the real workbook layout. This starter counts existing matching court names and scan dates in the loaded workbook.
- The app exports an Excel file. Direct Google Sheets synchronization is not configured in this source.
- Test on a real Android device; GitHub Actions build success does not prove runtime correctness.
