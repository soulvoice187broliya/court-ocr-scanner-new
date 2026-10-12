Court OCR Scanner

A Flutter Android application for scanning court documents, reviewing extracted OCR data, and exporting an Excel register.

Features

- On-device OCR for supported Latin-script text.
- Camera and gallery document input, subject to the implemented permissions and dependencies.
- Editable review form before saving or exporting extracted data.
- Excel workbook import and register export.
- Support for the configured register columns: A, B, C, D, E, F, G, H, I, J, K, P, Q, R, T, W, AE, AF, and AM.
- Configurable W assignee options saved in app settings.
- Dropdown options for AE, AF, and AM.
- Excel export through the Android share sheet.
- Date formatting in DD/MM/YYYY format and month/year conversion helpers.

Required repository structure

The repository root must contain:

- "pubspec.yaml"
- "lib/main.dart"
- ".github/workflows/build-apk.yml"

Any additional Dart files, Android configuration, assets, and tests required by the application must also be included.

Build the Android APK using GitHub Actions

1. Upload the complete Flutter project to the root of your GitHub repository on the "main" branch.
2. Confirm that ".github/workflows/build-apk.yml" exists on that branch.
3. Open the repository's Actions tab.
4. Select Build Court OCR Scanner APK.
5. Select Run workflow and choose "main", if the manual trigger is enabled.
6. Wait for the build, analysis, and test steps to finish successfully.
7. Open the successful workflow run and download the "Court-OCR-Scanner-APK" artifact.
8. Extract the downloaded ZIP archive. The APK filename depends on the workflow configuration; by default, Flutter generates "app-release.apk".
9. Transfer the APK to your Android phone and install it. Allow installation from that source if Android requests permission.

Do not install an artifact from a failed workflow run.

Build verification

The workflow should:

1. Check out the repository.
2. Set up Java and Flutter.
3. Resolve Flutter dependencies.
4. Run "flutter analyze".
5. Run "flutter test".
6. Build the release APK.
7. Verify that the expected APK file exists.
8. Upload the APK as a downloadable artifact.

These steps must be confirmed against the actual workflow file. A successful build has not been established by this README alone.

Excel register behavior

The application is intended to load an existing ".xlsx" workbook and append records to the configured worksheet while preserving unrelated columns.

Before using an existing register:

- Back up the original workbook.
- Verify the worksheet name and column mapping.
- Check that new records are appended to the correct rows.
- Confirm daily serial numbering and court-registration numbering against the real register.
- Review dates, case numbers, police stations, order types, designations, names, and addresses before exporting.

Date formatting

Dates should use "DD/MM/YYYY". Month/year conversion should return the expected abbreviated month and year, such as "Sep2026" for "19/09/2026".

Invalid dates must be rejected rather than silently converted into different calendar dates.

Limitations and data accuracy

- OCR extraction uses heuristics and is not a certified legal-document parser.
- Recognition accuracy depends on image quality, document layout, language, and handwriting or print quality.
- Review every extracted field against the original document before official use.
- Test workbook compatibility and serial numbering with a copy of the actual register.
- Test the application on a real Android device.

Google Sheets integration: Direct synchronization with Google Sheets is not configured in this version. The application exports Excel files; it does not automatically update an online Google Sheet.

Security and data handling

Court documents may contain confidential personal information. Store exported files securely, restrict sharing, and use only approved storage and transfer methods.

Release status

The source code and workflow must pass analysis, tests, and APK compilation before a release can be considered build-verified. Successful compilation does not, by itself, prove that OCR extraction, workbook updates, or runtime permissions work correctly.