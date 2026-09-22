#!/usr/bin/env python3
"""
So sánh DDL (định nghĩa sẵn) với schema thực tế trên BigQuery.
Cả 2 phần nằm chung 1 file markdown, đặt trong folder input/, phân biệt
bằng 2 heading cấp 1 (#):

    # DDL define
    ## HRP1000
    PLVAR
    OTYPE
    OBJID
    ...

    # BigQuery example
    ## HRP1000
    MANDT	PLVAR	OTYPE	OBJID	...

Quy tắc đọc file:
    - Heading "#"  => section (phải có đúng 1 section DDL và 1 section
      BigQuery; section BigQuery được nhận diện qua heading chứa chữ
      "bigquery" hoặc "bq", không phân biệt hoa/thường).
    - Heading "##" => tên bảng.
    - Dưới mỗi bảng: mỗi cột 1 dòng, hoặc nhiều cột trên 1 dòng cách nhau
      bằng tab / space / dấu phẩy / dấu chấm phẩy / dấu gạch đứng.
    - Tự động làm sạch ký tự lạ khi copy-paste: zero-width space, NBSP,
      khoảng trắng Unicode, ký tự full-width, dấu backtick/nháy bao quanh
      tên cột, bullet "-", "*", "•" ở đầu dòng.

Cách dùng:
    python compare-ddl-bigquery.py input/compare-ddl-bigquery.md

    # Tuỳ chọn
    --ignore-order      bỏ qua kiểm tra thứ tự cột
    --case-sensitive    phân biệt hoa/thường (mặc định: không phân biệt)
    --csv report.csv    xuất báo cáo ra CSV
"""
import argparse
import csv
import re
import sys
import unicodedata
from collections import OrderedDict, Counter

# Cảnh báo phát hiện khi làm sạch text (ký tự lạ, tên cột không hợp lệ...)
WARNINGS = []
VALID_COL = re.compile(r"^[A-Za-z0-9_/]+$")


def clean_line(raw):
    """Làm sạch 1 dòng: bỏ ký tự vô hình (zero-width, BOM, control...),
    đổi NBSP / khoảng trắng Unicode thành space, chuẩn hoá full-width -> ASCII.
    Trả về (dòng_đã_sạch, danh_sách_ký_tự_lạ_đã_xử_lý)."""
    out, odd = [], []
    for ch in raw:
        if ord(ch) > 127 or (unicodedata.category(ch).startswith("C") and ch != "\t"):
            odd.append(ch)
        for c in unicodedata.normalize("NFKC", ch):
            cat = unicodedata.category(c)
            if c in (" ", "\t"):
                out.append(c)
            elif cat.startswith("Z"):
                out.append(" ")
            elif cat in ("Cf", "Cc", "Co", "Cs", "Cn"):
                continue
            else:
                out.append(c)
    return "".join(out), odd


def describe_char(ch):
    try:
        name = unicodedata.name(ch)
    except ValueError:
        name = "UNKNOWN"
    return f"U+{ord(ch):04X} {name}"


def parse_markdown(text, source=""):
    """Trả về OrderedDict: section (heading #) -> OrderedDict: table (##) -> list[column]."""
    sections = OrderedDict()
    section = None
    table = None
    in_code = False

    for lineno, raw in enumerate(text.splitlines(), 1):
        cleaned, odd = clean_line(raw)
        line = cleaned.strip()
        # Bỏ bullet markdown ở đầu dòng: "- COL", "* COL", "• COL"
        line = re.sub(r"^[-*+•]\s+", "", line)
        if odd and line:
            kinds = ", ".join(sorted({describe_char(c) for c in odd}))
            WARNINGS.append(f"[{source or 'input'}:{lineno}] ký tự lạ đã được loại bỏ/chuẩn hoá: {kinds}")

        if line.startswith("```"):
            in_code = not in_code
            continue
        if not line:
            continue

        m1 = re.match(r"^#\s+(.*)$", line)
        m2 = re.match(r"^##\s+(.*)$", line)
        if m2:
            if section is None:
                sys.exit(f"[{source}:{lineno}] Gặp heading '##' trước khi có heading '#' section.")
            table = m2.group(1).strip()
            sections[section].setdefault(table, [])
            continue
        if m1:
            section = m1.group(1).strip()
            table = None
            sections.setdefault(section, OrderedDict())
            continue

        if table is None:
            continue

        tokens = []
        for t in re.split(r"[\s,;|]+", line):
            t = t.strip("`'\"“”‘’")
            if not t:
                continue
            if not VALID_COL.match(t):
                WARNINGS.append(f"[{source or 'input'}:{lineno}] bảng {table}: tên cột nghi ngờ "
                                f"{t!r} (chứa ký tự ngoài A-Z, 0-9, _, /)")
            tokens.append(t)
        sections[section][table].extend(tokens)

    return sections


def merge_tables(tables_dict):
    merged = OrderedDict()
    for name, cols in tables_dict.items():
        merged.setdefault(name, []).extend(cols)
    return merged


def split_ddl_bq(sections, source):
    bq_secs = [s for s in sections if re.search(r"bigquery|\bbq\b", s, re.I)]
    ddl_secs = [s for s in sections if s not in bq_secs]
    if len(bq_secs) != 1 or len(ddl_secs) != 1:
        sys.exit(
            f"[{source}] Cần đúng 1 heading '#' cho DDL và 1 heading '#' cho BigQuery "
            f"(heading BigQuery phải chứa chữ 'bigquery' hoặc 'bq'). "
            f"Tìm thấy DDL: {ddl_secs} | BigQuery: {bq_secs}"
        )
    ddl = merge_tables(sections[ddl_secs[0]])
    bq = merge_tables(sections[bq_secs[0]])
    return ddl, bq


def compare_table(ddl_cols, bq_cols, ignore_order, case_sensitive):
    norm = (lambda c: c) if case_sensitive else (lambda c: c.upper())
    d = [norm(c) for c in ddl_cols]
    b = [norm(c) for c in bq_cols]

    issues = []
    dup_d = [c for c, n in Counter(d).items() if n > 1]
    dup_b = [c for c, n in Counter(b).items() if n > 1]
    for c in dup_d:
        issues.append(("DUPLICATE_IN_DDL", c, ""))
    for c in dup_b:
        issues.append(("DUPLICATE_IN_BQ", c, ""))

    set_b = set(b)
    set_d = set(d)
    for c in d:
        if c not in set_b:
            issues.append(("MISSING_IN_BQ", c, "có trong DDL, không có trên BigQuery"))
    for c in b:
        if c not in set_d:
            issues.append(("EXTRA_IN_BQ", c, "có trên BigQuery, không có trong DDL"))

    if not ignore_order:
        common_d = [c for c in dict.fromkeys(d) if c in set_b]
        common_b = [c for c in dict.fromkeys(b) if c in set_d]
        if common_d != common_b:
            for i, (x, y) in enumerate(zip(common_d, common_b), 1):
                if x != y:
                    issues.append(("ORDER_DIFF", f"vị trí {i}", f"DDL={x} | BQ={y}"))
                    break
    return issues


def main():
    ap = argparse.ArgumentParser(description="So sánh DDL vs BigQuery schema (1 file markdown, 2 heading #)")
    ap.add_argument("file", nargs="?", default="input/compare-ddl-bigquery.md",
                     help="đường dẫn file markdown trong folder input (mặc định: input/compare-ddl-bigquery.md)")
    ap.add_argument("--ignore-order", action="store_true")
    ap.add_argument("--case-sensitive", action="store_true")
    ap.add_argument("--csv", help="xuất báo cáo ra file CSV")
    args = ap.parse_args()

    try:
        with open(args.file, encoding="utf-8") as f:
            text = f.read()
    except FileNotFoundError:
        sys.exit(f"Không tìm thấy file: {args.file}")

    sections = parse_markdown(text, args.file)
    ddl, bq = split_ddl_bq(sections, args.file)

    if WARNINGS:
        print(f"⚠️  {len(WARNINGS)} cảnh báo khi đọc file (ký tự lạ đã được làm sạch tự động):")
        for w in WARNINGS:
            print("  " + w)
        print()

    norm_name = (lambda t: t) if args.case_sensitive else (lambda t: t.upper())
    ddl = OrderedDict((norm_name(k), v) for k, v in ddl.items())
    bq = OrderedDict((norm_name(k), v) for k, v in bq.items())

    rows = []  # (table, status, type, detail, note)
    ok_tables = 0

    for t in ddl:
        if t not in bq:
            rows.append((t, "TABLE_MISSING_IN_BQ", "", "", "Không có bảng trên BigQuery"))
            continue
        issues = compare_table(ddl[t], bq[t], args.ignore_order, args.case_sensitive)
        if not issues:
            ok_tables += 1
        for typ, col, note in issues:
            rows.append((t, "DIFF", typ, col, note))
    for t in bq:
        if t not in ddl:
            rows.append((t, "TABLE_MISSING_IN_DDL", "", "", "Có bảng trên BigQuery nhưng chưa có DDL"))

    print(f"Tổng bảng DDL: {len(ddl)} | Tổng bảng BQ: {len(bq)} | Khớp hoàn toàn: {ok_tables}\n")
    if not rows:
        print("✅ Tất cả bảng khớp.")
    else:
        current = None
        for t, status, typ, col, note in rows:
            if t != current:
                print(f"\n=== {t} ===")
                current = t
            if status != "DIFF":
                print(f"  [{status}] {note}")
            else:
                extra = f"  ({note})" if note else ""
                print(f"  [{typ}] {col}{extra}")

    if args.csv:
        with open(args.csv, "w", newline="", encoding="utf-8-sig") as f:
            w = csv.writer(f)
            w.writerow(["table", "status", "issue_type", "column_or_position", "note"])
            w.writerows(rows)
        print(f"\nĐã ghi báo cáo: {args.csv}")

    sys.exit(1 if rows else 0)


if __name__ == "__main__":
    main()
