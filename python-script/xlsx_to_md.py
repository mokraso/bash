#!/usr/bin/env python3
"""Convert every sheet of an .xlsx file into a Markdown file.

Usage:
    python3 xlsx_to_md.py <path-to-file.xlsx> [--output-dir output]

Each sheet becomes a "## <sheet name>" heading followed by a Markdown table.
Output is written to <output-dir>/xlsx2md_<timestamp>.md
"""

import argparse
import datetime
import os
import sys

try:
    from openpyxl import load_workbook
except ImportError:
    sys.exit(
        "Missing dependency 'openpyxl'. Install it first, e.g.:\n"
        "    pip install openpyxl\n"
        "(use a virtualenv, pipx, or --break-system-packages if your "
        "system Python is externally managed)"
    )


def cell_to_str(value):
    if value is None:
        return ""
    text = str(value)
    # Escape characters that would break the Markdown table syntax.
    text = text.replace("\\", "\\\\").replace("|", "\\|")
    text = text.replace("\r\n", "<br>").replace("\n", "<br>").replace("\r", "<br>")
    return text.strip()


def sheet_to_markdown(sheet):
    rows = list(sheet.iter_rows(values_only=True))
    # Drop fully empty trailing rows/columns noise.
    rows = [row for row in rows if any(v is not None for v in row)]

    if not rows:
        return "_Sheet is empty._\n"

    header = [cell_to_str(v) for v in rows[0]]
    data_rows = rows[1:]

    lines = []
    lines.append("| " + " | ".join(header) + " |")
    lines.append("| " + " | ".join(["---"] * len(header)) + " |")
    for row in data_rows:
        cells = [cell_to_str(v) for v in row]
        # Pad/truncate to header width so the table stays well-formed.
        if len(cells) < len(header):
            cells += [""] * (len(header) - len(cells))
        elif len(cells) > len(header):
            cells = cells[: len(header)]
        lines.append("| " + " | ".join(cells) + " |")

    return "\n".join(lines) + "\n"


def convert(xlsx_path, output_dir):
    if not os.path.isfile(xlsx_path):
        sys.exit(f"File not found: {xlsx_path}")

    workbook = load_workbook(xlsx_path, data_only=True, read_only=True)

    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = os.path.join(output_dir, f"xlsx2md_{timestamp}.md")

    source_name = os.path.basename(xlsx_path)
    parts = [f"# {source_name}\n"]
    for sheet_name in workbook.sheetnames:
        sheet = workbook[sheet_name]
        parts.append(f"## {sheet_name}\n")
        parts.append(sheet_to_markdown(sheet))
        parts.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(parts))

    return output_path


def main():
    parser = argparse.ArgumentParser(description="Convert xlsx sheets to a Markdown file.")
    parser.add_argument("xlsx_path", help="Path to the .xlsx file")
    parser.add_argument(
        "--output-dir",
        default="output",
        help="Directory to write the Markdown file into (default: ./output)",
    )
    args = parser.parse_args()

    output_path = convert(args.xlsx_path, args.output_dir)
    print(f"Wrote: {output_path}")


if __name__ == "__main__":
    main()
