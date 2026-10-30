#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_typos.py
------------
Công cụ sửa lỗi chính tả thủ công (interactive) cho file Markdown được OCR từ sách
(đặc biệt hữu ích khi OCR tiếng Việt sai nhiều).

CÁCH DÙNG:
    python fix_typos.py <file_markdown.md> <file_danh_sach_tu_sai.txt> [--pending pending.txt] [--ignore-case] [--no-color]

TRONG ĐÓ:
    <file_markdown.md>         : đường dẫn tới file markdown cần sửa.
    <file_danh_sach_tu_sai.txt>: file chứa danh sách từ/cụm từ sai chính tả, MỖI DÒNG
                                  là MỘT đơn vị tìm kiếm (có thể là 1 từ hoặc cả cụm
                                  nhiều từ, ví dụ: "nghành logisitcs").

LUỒNG XỬ LÝ (2 lượt, làm hết lượt 1 rồi mới sang lượt 2):

    LƯỢT 1 - tìm NGUYÊN CỤM (chỉ áp dụng với các dòng có từ 2 từ trở lên):
        Với mỗi dòng trong file wordlist có từ 2 từ trở lên, lấy NGUYÊN VẸN cả
        dòng đó làm 1 cụm, quét toàn bộ file markdown để tìm cụm đó (so khớp
        theo ranh giới từ). Xử lý xong hết TẤT CẢ các dòng/cụm này rồi mới
        chuyển sang lượt 2.

    LƯỢT 2 - tìm TỪNG TỪ RIÊNG LẺ:
        Tách tất cả các dòng trong wordlist thành từng từ đơn (theo khoảng
        trắng/dấu phẩy), gộp lại thành 1 danh sách từ (không trùng lặp, giữ
        thứ tự xuất hiện). Với mỗi từ, quét lại toàn bộ file markdown để tìm
        từ đó.

    (Nếu 1 dòng trong wordlist chỉ có đúng 1 từ thì dòng đó chỉ được xử lý ở
    LƯỢT 2, không lặp lại ở lượt 1, để tránh hỏi 2 lần cho cùng 1 từ.)

    Ở MỖI chỗ khớp (dù là lượt 1 hay lượt 2):
        - In nguyên dòng văn bản bằng MÀU KHÁC với phần chữ còn lại của script
          (để dễ phân biệt đâu là nội dung sách, đâu là thông báo của script),
          và chính từ/cụm vừa khớp được TÔ NỔI BẬT (nền/màu khác) ngay trong
          dòng đó. Nếu từ/cụm nằm ở ĐẦU dòng thì in thêm dòng NGAY TRƯỚC đó;
          nếu nằm ở CUỐI dòng thì in thêm dòng NGAY SAU đó -> để có đủ ngữ
          cảnh câu (vì câu có thể bị ngắt giữa 2 dòng do OCR).
        - Hỏi người dùng muốn làm gì với chỗ khớp đó (xem đầy đủ các lựa chọn
          trong biến HELP_TEXT bên dưới, hoặc gõ '$help' khi script đang chạy):
          nhập từ/cụm thay thế, 'y', 'n', 'cũ:mới', 'note:...', '$skip',
          '$list', '$quit', '$help'.
        - Tiêu đề mỗi chỗ khớp có "(còn N từ/cụm nữa trong hàng chờ)" để biết
          tiến độ xử lý tổng (lượt 1 + lượt 2) còn lại bao nhiêu.

    Sau khi xử lý xong (hoặc dừng giữa chừng bằng Ctrl+C / '$quit'), ghi đè
    file markdown (có backup .bak ở lần ghi đầu) và ghi file pending nếu có
    từ note: nào được thêm.
"""

import argparse
import re
import sys
from pathlib import Path


class QuitProgram(Exception):
    """Người dùng gõ '$quit' -> thoát hẳn chương trình ngay lập tức."""


class SkipTerm(Exception):
    """Người dùng gõ '$skip' -> bỏ qua HOÀN TOÀN từ/cụm đang xét (mọi chỗ
    khớp còn lại của nó), loại nó khỏi hàng chờ, chuyển sang từ/cụm kế tiếp."""

# ---- Màu ANSI dùng để in dòng văn bản gốc của sách, khác màu với phần còn lại ----
COLOR_DOC = "\033[96m"        # cyan sáng: phần còn lại của dòng khớp hiện tại
COLOR_CTX = "\033[2;36m"      # cyan mờ: dòng ngữ cảnh (câu trước)
COLOR_HIGHLIGHT = "\033[1;97;41m"  # trắng đậm, nền đỏ: chính từ/cụm vừa tìm thấy
COLOR_RESET = "\033[0m"


def colorize(text: str, color: str, enabled: bool) -> str:
    if not enabled:
        return text
    return f"{color}{text}{COLOR_RESET}"


def highlight_matches(line: str, pattern: re.Pattern, enabled: bool) -> str:
    """In lại `line` với MÀU DÒNG (COLOR_DOC) cho phần chữ bình thường, và một
    màu/nền khác hẳn (COLOR_HIGHLIGHT) cho đúng (các) đoạn khớp với `pattern`,
    để từ/cụm vừa tìm thấy nổi bật lên giữa dòng."""
    if not enabled:
        return line
    pieces = []
    last_end = 0
    for m in pattern.finditer(line):
        pieces.append(f"{COLOR_DOC}{line[last_end:m.start()]}{COLOR_RESET}")
        pieces.append(f"{COLOR_HIGHLIGHT}{line[m.start():m.end()]}{COLOR_RESET}")
        last_end = m.end()
    pieces.append(f"{COLOR_DOC}{line[last_end:]}{COLOR_RESET}")
    return "".join(pieces)


def load_wordlist_lines(path: Path):
    """Đọc file danh sách, trả về list các DÒNG (đã strip, bỏ dòng trống/comment),
    giữ nguyên thứ tự, không tách từ, không dedup (dùng cho lượt 1 - tìm nguyên cụm)."""
    lines = []
    text = path.read_text(encoding="utf-8")
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        lines.append(line)
    return lines


def split_into_words(line: str):
    parts = re.split(r"[,\s]+", line)
    return [w for w in parts if w]


def build_word_list(lines):
    """Tách tất cả các dòng thành từng từ đơn, gộp lại, bỏ trùng, giữ thứ tự
    xuất hiện đầu tiên (dùng cho lượt 2 - tìm từng từ riêng lẻ)."""
    words = []
    seen = set()
    for line in lines:
        for w in split_into_words(line):
            if w not in seen:
                seen.add(w)
                words.append(w)
    return words


def build_pattern(term: str, ignore_case: bool) -> re.Pattern:
    flags = re.IGNORECASE if ignore_case else 0
    return re.compile(r"(?<!\w)" + re.escape(term) + r"(?!\w)", flags)


# Những ký tự coi là "mở đầu dòng" (bullet markdown, số thứ tự, khoảng trắng...),
# không tính là một từ đứng trước -> nếu sau các ký tự này là từ khớp thì coi như
# từ đó nằm ở đầu câu/đầu dòng.
_LEADING_MARKUP_RE = re.compile(r"^[\s\-\*#>\d\.\)]*$")


def is_at_line_start(line: str, match_start: int) -> bool:
    """Trả về True nếu đoạn trước vị trí match chỉ gồm khoảng trắng / ký tự
    markdown mở đầu dòng (bullet, số thứ tự, #, >...), tức từ/cụm khớp coi như
    đứng ở đầu câu/đầu dòng."""
    prefix = line[:match_start]
    return bool(_LEADING_MARKUP_RE.match(prefix))


# Những ký tự coi là "cuối dòng" (dấu câu kết thúc, dấu đóng ngoặc, khoảng
# trắng...), không tính là một từ đứng sau -> nếu trước các ký tự này là từ
# khớp thì coi như từ đó nằm ở cuối câu/cuối dòng.
_TRAILING_MARKUP_RE = re.compile(r"^[\s\-\*\.\,\;\:\)\]\}\"'!\?]*$")


def is_at_line_end(line: str, match_end: int) -> bool:
    """Trả về True nếu đoạn sau vị trí match chỉ gồm khoảng trắng / dấu câu
    kết thúc dòng (., ,, ;, :, ), ], }, ! , ?...), tức từ/cụm khớp coi như
    đứng ở cuối câu/cuối dòng."""
    suffix = line[match_end:]
    return bool(_TRAILING_MARKUP_RE.match(suffix))


def append_pending(path: Path, term: str):
    with path.open("a", encoding="utf-8") as f:
        f.write(term + "\n")


HELP_TEXT = """\
Các lựa chọn có thể nhập tại dấu nhắc:
  <từ/cụm>      thay thế TẤT CẢ chỗ khớp của từ/cụm đang tìm TRONG DÒNG này
                (được nhớ lại làm "gần nhất" để dùng với 'y')
  y             dùng lại y nguyên từ thay thế gần nhất (cho từ/cụm đang tìm)
  n             bỏ qua (next), sang chỗ khớp kế tiếp
  cũ:mới        sửa 1 đoạn KHÁC bất kỳ trong CÙNG dòng này, vd: "ngan bo: ngắn bỏ"
  note:a, b     thêm a, b (tự trim khoảng trắng) vào danh sách chờ cho lần
                chạy sau; chỗ khớp hiện tại vẫn được hỏi lại, không bị bỏ qua
  $skip         bỏ qua HOÀN TOÀN từ/cụm đang tìm (mọi chỗ khớp còn lại),
                loại khỏi hàng chờ, qua từ/cụm kế tiếp
  $list         xem danh sách các từ/cụm còn lại trong hàng chờ (sau từ này)
  $quit         lưu lại tiến trình và thoát chương trình ngay
  $help         hiện lại bảng hướng dẫn này\
"""


def process_term(term, lines, pending_path, ignore_case, use_color, stats,
                  remaining_terms=None):
    """Quét toàn bộ `lines` để tìm `term`, hỏi người dùng xử lý từng chỗ khớp.
    Cập nhật `lines` tại chỗ. `stats` là dict đếm: changed, replaced, notes.
    `remaining_terms`: list các từ/cụm CÒN LẠI trong hàng chờ SAU từ/cụm này
    (để hiển thị số lượng, và cho action '$list'), None nếu không cần.
    Có thể raise QuitProgram hoặc SkipTerm."""
    pattern = build_pattern(term, ignore_case)
    last_replacement = None  # "từ thay thế gần nhất" riêng cho `term` này
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        matches = list(pattern.finditer(line))
        if not matches:
            idx += 1
            continue
        first_m, last_m = matches[0], matches[-1]

        print("\n" + "-" * 60)
        header = f"[Đang tìm: '{term}']  Dòng {idx + 1}:"
        if remaining_terms is not None:
            header += f"  (còn {len(remaining_terms)} từ/cụm nữa trong hàng chờ)"
        print(header)
        if is_at_line_start(line, first_m.start()) and idx > 0:
            print("  (câu/dòng trước đó):", colorize(lines[idx - 1], COLOR_CTX, use_color))
        print(highlight_matches(line, pattern, use_color))
        if is_at_line_end(line, last_m.end()) and idx < len(lines) - 1:
            print("  (dòng/câu phía sau):", colorize(lines[idx + 1], COLOR_CTX, use_color))

        prompt = "Nhập thay thế / 'y' / 'n' / 'cũ:mới' / 'note:' / $help: "
        try:
            user_input = input(prompt).strip()
        except EOFError:
            user_input = "n"

        if user_input.lower() == "$help":
            print("\n" + HELP_TEXT)
            continue  # hỏi lại đúng chỗ khớp này

        if user_input.lower() == "$list":
            if remaining_terms:
                print(f"\nCòn {len(remaining_terms)} từ/cụm trong hàng chờ:")
                for j, t in enumerate(remaining_terms, 1):
                    print(f"  {j}. {t}")
            else:
                print("\nKhông còn từ/cụm nào khác trong hàng chờ.")
            continue  # hỏi lại đúng chỗ khớp này

        if user_input.lower() == "$quit":
            print("-> Thoát chương trình theo yêu cầu. Đang lưu lại tiến trình đã làm...")
            raise QuitProgram()

        if user_input.lower() == "$skip":
            print(f"-> Bỏ qua HOÀN TOÀN '{term}', loại khỏi hàng chờ.")
            raise SkipTerm()

        if user_input == "n" or user_input == "":
            idx += 1
            continue

        if user_input.lower().startswith("note:"):
            raw = user_input.split(":", 1)[1]
            note_terms = [t.strip() for t in raw.split(",") if t.strip()]
            for nt in note_terms:
                append_pending(pending_path, nt)
                stats["notes"] += 1
            if note_terms:
                print(f"-> Đã thêm vào danh sách chờ: {', '.join(note_terms)}")
            continue  # không tăng idx -> hiện lại đúng chỗ khớp này, không skip

        if ":" in user_input:
            # Cú pháp "đoạn_cũ:đoạn_mới" (hoặc "đoạn_cũ: đoạn_mới") -> sửa 1
            # đoạn BẤT KỲ khác trong CÙNG dòng này, không nhất thiết liên quan
            # trực tiếp tới `term` đang tìm. Ví dụ đang tìm 'bo' trong dòng
            # "Tham ngan bo dài", gõ "ngan bo: ngắn bỏ" -> "Tham ngắn bỏ dài".
            old_part, new_part = user_input.split(":", 1)
            old_part = old_part.strip()
            new_part = new_part.strip()
            if old_part and new_part:
                fix_pattern = build_pattern(old_part, ignore_case)
                new_line, n_sub = fix_pattern.subn(new_part, line)
                if n_sub > 0:
                    lines[idx] = new_line
                    stats["changed"] = True
                    stats["replaced"] += n_sub
                    print(f"-> Đã sửa '{old_part}' -> '{new_part}' ({n_sub} chỗ trong dòng).")
                else:
                    print(f"-> Không tìm thấy '{old_part}' trong dòng này để sửa.")
            else:
                print("-> Cú pháp không hợp lệ, cần dạng 'đoạn_cũ:đoạn_mới'.")
            # Không tăng idx: vòng lặp sẽ tự kiểm tra lại dòng (đã có thể đổi
            # nội dung) xem `term` đang tìm còn khớp hay không.
            continue

        if user_input.lower() == "y":
            if last_replacement is None:
                print("-> Chưa có từ thay thế nào trước đó để dùng lại bằng 'y'. "
                      "Hãy nhập từ thay thế trước.")
                continue  # hỏi lại đúng chỗ khớp này
            user_input = last_replacement

        new_line, n_sub = pattern.subn(user_input, line)
        lines[idx] = new_line
        last_replacement = user_input
        stats["changed"] = True
        stats["replaced"] += n_sub
        print(f"-> Đã thay '{term}' -> '{user_input}' ({n_sub} chỗ trong dòng).")
        idx += 1


def main():
    parser = argparse.ArgumentParser(
        description="Sửa lỗi chính tả thủ công (interactive) trong file markdown OCR."
    )
    parser.add_argument("markdown", type=Path, help="File markdown cần sửa")
    parser.add_argument("wordlist", type=Path, help="File danh sách từ/cụm sai chính tả")
    parser.add_argument(
        "--pending",
        type=Path,
        default=None,
        help="File lưu danh sách chờ (mặc định: pending_<tên wordlist>.txt cùng thư mục)",
    )
    parser.add_argument(
        "--ignore-case",
        action="store_true",
        help="So khớp không phân biệt hoa/thường",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="Tắt in màu (nếu terminal không hỗ trợ ANSI color)",
    )
    args = parser.parse_args()

    md_path: Path = args.markdown
    wl_path: Path = args.wordlist
    use_color = not args.no_color

    if not md_path.exists():
        sys.exit(f"Không tìm thấy file markdown: {md_path}")
    if not wl_path.exists():
        sys.exit(f"Không tìm thấy file danh sách từ sai: {wl_path}")

    pending_path: Path = args.pending or (wl_path.parent / f"pending_{wl_path.name}")

    wl_lines = load_wordlist_lines(wl_path)
    if not wl_lines:
        sys.exit("Danh sách từ sai rỗng, không có gì để xử lý.")

    # Cụm nhiều từ (>=2 từ) dùng cho lượt 1; từ đơn lẻ sẽ được gộp vào lượt 2.
    phrases = [ln for ln in wl_lines if len(split_into_words(ln)) >= 2]
    words = build_word_list(wl_lines)

    # Hàng chờ tổng (lượt 1 + lượt 2), dùng cho "còn bao nhiêu từ nữa" / '$list'.
    queue = phrases + words

    original_text = md_path.read_text(encoding="utf-8")
    lines = original_text.split("\n")

    stats = {"changed": False, "replaced": 0, "notes": 0}

    try:
        for i, term in enumerate(queue):
            remaining_terms = queue[i + 1:]
            try:
                process_term(
                    term, lines, pending_path, args.ignore_case, use_color,
                    stats, remaining_terms=remaining_terms,
                )
            except SkipTerm:
                continue
    except (KeyboardInterrupt, QuitProgram):
        print("\nĐã dừng. Đang lưu lại tiến trình đã làm...")
    finally:
        if stats["changed"]:
            backup_path = md_path.with_suffix(md_path.suffix + ".bak")
            if not backup_path.exists():
                backup_path.write_text(original_text, encoding="utf-8")
            md_path.write_text("\n".join(lines), encoding="utf-8")
            print(f"\nĐã lưu file markdown: {md_path}")
            print(f"Backup bản gốc tại: {backup_path}")
        else:
            print("\nKhông có thay đổi nào được lưu.")

        if stats["notes"]:
            print(f"Đã thêm {stats['notes']} từ/cụm vào danh sách chờ: {pending_path}")

        print(f"Tổng số lượt thay thế: {stats['replaced']}")


if __name__ == "__main__":
    main()
