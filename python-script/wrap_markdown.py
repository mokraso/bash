#!/usr/bin/env python3
"""
wrap_md.py — Ngắt (wrap) các dòng văn bản quá dài trong file Markdown
thành nhiều dòng ngắn hơn, mỗi dòng mặc định WORDS_PER_LINE từ.

Chỉ ngắt xuống 1 dòng (single \\n), KHÔNG chèn dòng trống, vì khi
render trên GitHub/CommonMark, các dòng liền nhau trong một đoạn văn
sẽ tự động được gộp lại thành một dòng/đoạn — nên việc ngắt dòng ở
file nguồn chỉ giúp dễ đọc/dễ diff trong text editor, không ảnh hưởng
tới cách hiển thị khi render.

Các dòng sau được GIỮ NGUYÊN, không ngắt:
- Dòng heading (bắt đầu bằng #)
- Dòng trống
- Dòng trong code block (giữa hai dòng ```)
- Dòng list (-, *, +, hoặc số thứ tự "1.", "2)"...)
- Blockquote (>)
- Table row (|...|)
- Horizontal rule (---, ***, ___)

Nếu đoạn cuối cùng của một dòng còn lại quá ít từ (ít hơn
--min-tail-words), số từ đó sẽ được cộng dồn vào dòng ngay trước đó
thay vì tách riêng thành một dòng "mồ côi" chỉ có vài từ.

Cách dùng:
    python3 wrap_md.py input.md
        -> ghi ra input-wrap.md (tự thêm suffix "-wrap" trước phần đuôi mở rộng)
    python3 wrap_md.py input.md -o output.md
    python3 wrap_md.py input.md --words-per-line 12
    python3 wrap_md.py input.md --words-per-line 12 --min-tail-words 4
"""

import argparse
import re
import sys
from pathlib import Path

HEADING_RE = re.compile(r"^#{1,6}\s")
LIST_RE = re.compile(r"^(\s*)([-*+]\s|\d+[.)]\s)")
BLOCKQUOTE_RE = re.compile(r"^\s*>")
TABLE_ROW_RE = re.compile(r"^\s*\|")
HR_RE = re.compile(r"^\s*(-{3,}|\*{3,}|_{3,})\s*$")
CODE_FENCE_RE = re.compile(r"^\s*(```|~~~)")


def wrap_line(text: str, words_per_line: int, min_tail_words: int) -> list[str]:
    """Chia 1 dòng văn bản thành nhiều dòng theo số từ, dồn phần đuôi quá ngắn vào dòng trước."""
    words = text.split(" ")
    # Loại bỏ các khoảng trắng rỗng do nhiều dấu cách liền nhau (giữ lại nếu cần có thể chỉnh)
    words = [w for w in words if w != ""]
    if not words:
        return [text]

    chunks: list[list[str]] = []
    for i in range(0, len(words), words_per_line):
        chunks.append(words[i:i + words_per_line])

    # Nếu dòng cuối quá ngắn, cộng dồn vào dòng kế trước (khi có >1 chunk)
    if len(chunks) > 1 and len(chunks[-1]) < min_tail_words:
        tail = chunks.pop()
        chunks[-1].extend(tail)

    return [" ".join(chunk) for chunk in chunks]


def should_skip(line: str, in_code_block: bool) -> bool:
    stripped = line.strip()
    if stripped == "":
        return True
    if HEADING_RE.match(line):
        return True
    if LIST_RE.match(line):
        return True
    if BLOCKQUOTE_RE.match(line):
        return True
    if TABLE_ROW_RE.match(line):
        return True
    if HR_RE.match(line):
        return True
    return False


def process(lines: list[str], words_per_line: int, min_tail_words: int) -> list[str]:
    out: list[str] = []
    in_code_block = False

    for line in lines:
        if CODE_FENCE_RE.match(line):
            in_code_block = not in_code_block
            out.append(line)
            continue

        if in_code_block or should_skip(line, in_code_block):
            out.append(line)
            continue

        wrapped = wrap_line(line.rstrip("\n"), words_per_line, min_tail_words)
        out.extend(wrapped)

    return out


def main():
    parser = argparse.ArgumentParser(description="Ngắt dòng dài trong file Markdown theo số từ.")
    parser.add_argument("input", help="File markdown đầu vào")
    parser.add_argument("-o", "--output",
                         help="File markdown đầu ra (mặc định: <input>-wrap<đuôi mở rộng>, "
                              "cùng thư mục với input)")
    parser.add_argument("--words-per-line", type=int, default=15,
                         help="Số từ mặc định mỗi dòng (mặc định: 15)")
    parser.add_argument("--min-tail-words", type=int, default=None,
                         help="Số từ tối thiểu cho dòng cuối của mỗi đoạn; "
                              "nếu ít hơn sẽ dồn vào dòng trước (mặc định: words-per-line // 2)")
    args = parser.parse_args()

    min_tail_words = args.min_tail_words
    if min_tail_words is None:
        min_tail_words = max(1, args.words_per_line // 2)

    input_path = Path(args.input)
    with open(input_path, encoding="utf-8") as f:
        lines = f.read().split("\n")

    result_lines = process(lines, args.words_per_line, min_tail_words)
    result = "\n".join(result_lines)

    if args.output:
        output_path = Path(args.output)
    else:
        output_path = input_path.with_name(input_path.stem + "-wrap" + input_path.suffix)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(result)
    print(f"Đã ghi kết quả vào: {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
