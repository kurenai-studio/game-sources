# Combining a class's Progress Reports

Students export a Progress Report from the Zone Map and attach it to a Google Classroom assignment. The report combiner turns a whole class's reports into one spreadsheet, with one row per student per Puzzle.

## One-time setup

You need Python 3.11 or newer ([python.org](https://www.python.org/downloads/)) and a copy of the Structura source folder. In PowerShell, from inside that folder:

```powershell
py -m venv .venv
.venv\Scripts\pip install -e .
```

## Each time you collect reports

1. In Google Classroom, open the assignment, open its Drive folder and download it. Unzip the download. Subfolders are fine.
2. From inside the Structura folder, run:

   ```powershell
   .venv\Scripts\structura-combine "C:\Users\you\Downloads\Prelim reports" prelim.csv
   ```

3. Open `prelim.csv` in Excel or Google Sheets.

## What the spreadsheet shows

| Column | Meaning |
|---|---|
| Student, Student ID | As the student typed them when creating their Profile |
| Zone, Puzzle, Stage | Which Puzzle the row is about |
| Stars | 0 to 3. 0 means not finished yet |
| Moves, Reference Moves | The student's best run, and the Moves in the Reference Solution |
| Glitches, Hints | In that best run |
| Attempts | How many times the student finished the Puzzle |
| Completed | When the best run was finished (UTC) |
| Verified | `yes` if the report is exactly as the game wrote it; `no` if it fails signature verification |

Grade on completion (Stars above 0), not on the number of Stars. Stars reward efficiency, and grading them pushes students to look up answers.

## Messages the combiner prints

- **Flagged … fails signature verification.** The report was changed after the game exported it, most likely by hand in a text editor. Its rows are still in the spreadsheet, marked `no` in Verified, showing the edited values. Follow up with the student. The signature deters casual editing; it is not proof against a student who reads the game's source code.
- **Skipped … not a Progress Report.** The file is something else (a photo, a document, a different JSON file). Nothing from it is in the spreadsheet.
- **Skipped … a damaged Progress Report.** It looks like a report but parts of it are missing. Ask the student to export again.
- **Skipped … sent a newer report.** A student submitted more than one report. Only the newest (by the time the game exported it) is used.
- **Couldn't write prelim.csv.** The spreadsheet is probably still open in Excel from last time. Close it and run the command again.

A name that starts with `=`, `+`, `-`, `@` or a similar character is shown with a leading `'` so the spreadsheet treats it as text rather than a formula.

Excel may drop leading zeros from Student IDs such as `00123`. If your IDs have them, import the CSV through **Data → From Text/CSV** and set the Student ID column to Text.
