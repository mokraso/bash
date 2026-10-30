#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_typos.py
------------
Công cụ sửa lỗi chính tả thủ công (interactive) cho file Markdown được OCR từ sách
(đặc biệt hữu ích khi OCR tiếng Việt sai nhiều).

CÁCH DÙNG:
    python fix_typos.py <file_markdown.md> <file_danh_sach_tu_sai.txt> \
        [--pending pending.txt] [--ignore-file ignore.txt] [--ignore-case] [--no-color]

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
        - Hỏi người dùng muốn làm gì với chỗ khớp đó (xem đầy đủ trong biến
          HELP_TEXT bên dưới, hoặc gõ '$help' khi script đang chạy). 'y' và
          'n' gõ TRẦN như cũ (không có "$"); mọi action khác theo cú pháp
          "$<action> [params]": $fix cũ:mới, $note ..., $skip, $skip cụm,
          $global cũ:mới (viết tắt $g), $list, $quit, $help. Gõ trực tiếp
          từ/cụm khác (không có "$", không phải 'y'/'n') tương đương
          "$replace <từ/cụm>" - tức thay thế ngay bằng đúng những gì vừa gõ.
        - Tiêu đề mỗi chỗ khớp có "(còn N từ/cụm nữa trong hàng chờ)" để biết
          tiến độ xử lý tổng (lượt 1 + lượt 2) còn lại bao nhiêu.

    '$skip cụm' (khác với '$skip' đứng một mình): dùng khi từ đang tìm chỉ là
    MỘT PHẦN của 1 cụm/từ ghép ĐÚNG chính tả (vd đang tìm 'định', gặp 'nhất
    định' vốn không sai) -> gõ "$skip nhất định" để từ nay (cả trong lượt
    chạy này lẫn các lần chạy sau) bỏ qua, không hỏi lại mỗi khi 'định' nằm
    trong cụm 'nhất định' nữa. Danh sách (key = từ đang tìm, value = cụm cần
    bỏ qua) được lưu vào 1 file riêng (giống file pending), mặc định
    ignore_<tên wordlist>.txt, nạp lại tự động ở các lần chạy sau.

    '$global cũ:mới': thay TOÀN BỘ chỗ khớp của "cũ" bằng "mới" trong CẢ FILE
    markdown ngay lập tức (không chỉ dòng đang xem, không chỉ từ/cụm đang
    tìm) -> dùng khi phát hiện 1 lỗi lặp lại nhiều nơi, không liên quan tới
    wordlist. Ví dụ: "$global y định:ý định".

    Sau khi xử lý xong (hoặc dừng giữa chừng bằng Ctrl+C / '$quit'), ghi đè
    file markdown (có backup .bak ở lần ghi đầu), ghi file pending nếu có
    '$note' nào được thêm, và ghi file ignore nếu có '$skip cụm' nào được
    thêm.
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


def load_ignore_map(path: Path):
    """Đọc file ignore (mỗi dòng dạng 'key: cụm'), trả về dict
    {key: [cụm1, cụm2, ...]}. Trả về {} nếu file chưa tồn tại."""
    ignore_map = {}
    if not path.exists():
        return ignore_map
    text = path.read_text(encoding="utf-8")
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, phrase = line.split(":", 1)
        key = key.strip()
        phrase = phrase.strip()
        if key and phrase:
            ignore_map.setdefault(key, [])
            if phrase not in ignore_map[key]:
                ignore_map[key].append(phrase)
    return ignore_map


def append_ignore(path: Path, key: str, phrase: str):
    with path.open("a", encoding="utf-8") as f:
        f.write(f"{key}: {phrase}\n")


HELP_TEXT = """\
CÚ PHÁP cho mọi action KHÁC 'y'/'n':  $<action> [params]
Riêng 'y' và 'n' gõ TRẦN, không có dấu "$". Gõ trực tiếp từ/cụm khác (không
có "$", không phải 'y'/'n') == "$replace <từ/cụm>".

  <từ/cụm>          == $replace <từ/cụm>: thay TẤT CẢ chỗ khớp của từ/cụm
                      đang tìm TRONG DÒNG này; được nhớ lại làm "gần nhất"
                      để dùng với 'y'
  y                 dùng lại y nguyên từ thay thế gần nhất (cho từ/cụm đang tìm)
  n                 bỏ qua (next), sang chỗ khớp kế tiếp (Enter trống = 'n')
  $fix cũ:mới       sửa 1 đoạn KHÁC bất kỳ trong CÙNG dòng này, vd:
                    "$fix ngan bo:ngắn bỏ"
  $note a, b        thêm a, b (tự trim khoảng trắng) vào danh sách chờ cho
                    lần chạy sau; chỗ khớp hiện tại vẫn được hỏi lại
  $note a:x         thêm "a" vào danh sách chờ, ĐỒNG THỜI thay "a"->"x" ngay
                    trong DÒNG hiện tại. Có thể trộn: "$note a:x, b" (b chỉ
                    note, không thay)
  $skip             bỏ qua HOÀN TOÀN từ/cụm đang tìm (mọi chỗ khớp còn lại),
                    loại khỏi hàng chờ, qua từ/cụm kế tiếp
  $skip cụm         từ/cụm đang tìm nằm trong 1 từ ghép ĐÚNG (vd tìm 'định'
                    gặp 'nhất định') -> từ nay bỏ qua, không hỏi lại mỗi khi
                    gặp cụm này nữa (lưu vào file ignore, áp dụng cả các lần
                    chạy sau)
  $global cũ:mới    (viết tắt: $g cũ:mới) thay TOÀN BỘ "cũ" -> "mới" trong
                    CẢ FILE ngay, không chỉ dòng/từ đang xét, vd:
                    "$g y định:ý định"
  $list             xem danh sách các từ/cụm còn lại trong hàng chờ
  $quit             lưu lại tiến trình và thoát chương trình ngay
  $help             hiện lại bảng hướng dẫn này\
"""


def filter_ignored_matches(line, matches, ignore_patterns):
    """Loại khỏi `matches` những match nằm TRỌN trong phạm vi khớp của bất kỳ
    pattern nào trong `ignore_patterns` (các cụm đã được đánh dấu bỏ qua bằng
    '$skip:cụm' cho chính `term` đang xét)."""
    if not ignore_patterns or not matches:
        return matches
    ignored_ranges = []
    for ip in ignore_patterns:
        for im in ip.finditer(line):
            ignored_ranges.append((im.start(), im.end()))
    if not ignored_ranges:
        return matches
    return [
        m for m in matches
        if not any(s <= m.start() and m.end() <= e for s, e in ignored_ranges)
    ]


def process_term(term, lines, pending_path, ignore_case, use_color, stats,
                  remaining_terms=None, ignore_map=None, ignore_path=None):
    """Quét toàn bộ `lines` để tìm `term`, hỏi người dùng xử lý từng chỗ khớp.
    Cập nhật `lines` tại chỗ. `stats` là dict đếm: changed, replaced, notes.
    `remaining_terms`: list các từ/cụm CÒN LẠI trong hàng chờ SAU từ/cụm này
    (để hiển thị số lượng, và cho action '$list'), None nếu không cần.
    `ignore_map`: dict {term: [cụm cần bỏ qua, ...]} (xem '$skip:cụm'), dùng
    chung cho mọi lần gọi trong suốt phiên chạy; `ignore_path` là file lưu nó.
    Có thể raise QuitProgram hoặc SkipTerm."""
    pattern = build_pattern(term, ignore_case)
    last_replacement = None  # "từ thay thế gần nhất" riêng cho `term` này
    if ignore_map is None:
        ignore_map = {}
    ignore_patterns = [build_pattern(p, ignore_case) for p in ignore_map.get(term, [])]
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        matches = filter_ignored_matches(line, list(pattern.finditer(line)), ignore_patterns)
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

        prompt = "Nhập thay thế / 'y' / 'n', hoặc $action (gõ $help): "
        try:
            user_input = input(prompt).strip()
        except EOFError:
            user_input = "n"

        # ---- Cú pháp cho mọi action khác (ngoại trừ 'y'/'n'): "$<action> [params]".
        # Riêng 'y' và 'n' vẫn gõ TRẦN không có dấu "$" (y: dùng lại thay thế
        # gần nhất; n hoặc Enter trống: bỏ qua). Gõ trực tiếp từ/cụm khác
        # (không có "$", không phải 'y'/'n') == "$replace <text>".
        if user_input == "" or user_input.lower() == "n":
            action, param = "n", ""
        elif user_input.lower() == "y":
            action, param = "y", ""
        elif user_input.startswith("$"):
            head, _, rest = user_input[1:].partition(" ")
            action = head.lower()
            param = rest.strip()
            if action == "g":
                action = "global"
        else:
            action = "replace"
            param = user_input

        if action == "help":
            print("\n" + HELP_TEXT)
            continue  # hỏi lại đúng chỗ khớp này

        if action == "list":
            if remaining_terms:
                print(f"\nCòn {len(remaining_terms)} từ/cụm trong hàng chờ:")
                for j, t in enumerate(remaining_terms, 1):
                    print(f"  {j}. {t}")
            else:
                print("\nKhông còn từ/cụm nào khác trong hàng chờ.")
            continue  # hỏi lại đúng chỗ khớp này

        if action == "quit":
            print("-> Thoát chương trình theo yêu cầu. Đang lưu lại tiến trình đã làm...")
            raise QuitProgram()

        if action == "skip":
            if not param:
                print(f"-> Bỏ qua HOÀN TOÀN '{term}', loại khỏi hàng chờ.")
                raise SkipTerm()
            # "$skip nhất định" -> `term` (vd 'định') nằm trong 1 cụm đúng
            # chính tả -> từ nay bỏ qua cụm này, không hỏi lại nữa (lưu file).
            skip_phrases = [t.strip() for t in param.split(",") if t.strip()]
            for sp in skip_phrases:
                if ignore_path is not None:
                    append_ignore(ignore_path, term, sp)
                ignore_map.setdefault(term, [])
                if sp not in ignore_map[term]:
                    ignore_map[term].append(sp)
                ignore_patterns.append(build_pattern(sp, ignore_case))
                stats["ignored"] += 1
            if skip_phrases:
                print(f"-> Từ nay bỏ qua '{term}' trong: {', '.join(skip_phrases)}")
            continue  # không tăng idx -> vòng lặp tự lọc lại, bỏ chỗ vừa thêm

        if action == "global":
            # "$global đoạn_cũ:đoạn_mới" -> thay TOÀN BỘ file, không chỉ dòng
            # hay từ/cụm đang xét. Ví dụ: "$global y định:ý định".
            if ":" not in param:
                print("-> Cú pháp không hợp lệ, cần dạng '$global cũ:mới'.")
                continue
            g_old, g_new = param.split(":", 1)
            g_old = g_old.strip()
            g_new = g_new.strip()
            if not g_old or not g_new:
                print("-> Cú pháp không hợp lệ, cần dạng '$global cũ:mới'.")
                continue
            g_pattern = build_pattern(g_old, ignore_case)
            total_sub = 0
            for li in range(len(lines)):
                new_li, n_sub = g_pattern.subn(g_new, lines[li])
                if n_sub:
                    lines[li] = new_li
                    total_sub += n_sub
            if total_sub:
                stats["changed"] = True
                stats["replaced"] += total_sub
            print(f"-> [GLOBAL] Đã thay '{g_old}' -> '{g_new}' ở {total_sub} chỗ trong cả file.")
            continue  # vòng lặp tự kiểm tra lại dòng hiện tại (có thể đã đổi)

        if action == "n":
            idx += 1
            continue

        if action == "note":
            # Mỗi phần tử cách nhau dấu phẩy. Phần tử dạng "word1:word2" nghĩa
            # là: note "word1" vào danh sách chờ, ĐỒNG THỜI thay "word1" ->
            # "word2" ngay trong DÒNG HIỆN TẠI. Phần tử không có ":" thì chỉ
            # note như cũ, không thay gì. Vd: "$note tu_a, tu_b:tu_c".
            items = [t.strip() for t in param.split(",") if t.strip()]
            if not items:
                print("-> Cú pháp không hợp lệ, cần dạng '$note word' hoặc '$note word:thay_thế'.")
                continue
            noted = []
            for item in items:
                if ":" in item:
                    note_word, local_new = item.split(":", 1)
                    note_word = note_word.strip()
                    local_new = local_new.strip()
                else:
                    note_word, local_new = item.strip(), None

                if not note_word:
                    continue
                append_pending(pending_path, note_word)
                stats["notes"] += 1
                noted.append(note_word)

                if local_new:
                    note_pattern = build_pattern(note_word, ignore_case)
                    new_line, n_sub = note_pattern.subn(local_new, line)
                    if n_sub:
                        lines[idx] = new_line
                        line = new_line  # để các phần tử note tiếp theo (nếu có) thấy dòng đã đổi
                        stats["changed"] = True
                        stats["replaced"] += n_sub
                        print(f"-> Đã thay '{note_word}' -> '{local_new}' "
                              f"({n_sub} chỗ trong dòng) và thêm '{note_word}' vào danh sách chờ.")
                    else:
                        print(f"-> Không tìm thấy '{note_word}' trong dòng này để thay, "
                              f"nhưng vẫn đã thêm vào danh sách chờ.")
            if noted and not any(":" in it for it in items):
                print(f"-> Đã thêm vào danh sách chờ: {', '.join(noted)}")
            continue  # không tăng idx -> hiện lại đúng chỗ khớp này, không skip

        if action == "fix":
            # "$fix đoạn_cũ:đoạn_mới" -> sửa 1 đoạn BẤT KỲ khác trong CÙNG
            # dòng này, không nhất thiết liên quan trực tiếp tới `term` đang
            # tìm. Ví dụ đang tìm 'bo' trong dòng "Tham ngan bo dài", gõ
            # "$fix ngan bo:ngắn bỏ" -> "Tham ngắn bỏ dài".
            if ":" not in param:
                print("-> Cú pháp không hợp lệ, cần dạng '$fix cũ:mới'.")
                continue
            old_part, new_part = param.split(":", 1)
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
                print("-> Cú pháp không hợp lệ, cần dạng '$fix cũ:mới'.")
            # Không tăng idx: vòng lặp sẽ tự kiểm tra lại dòng (đã có thể đổi
            # nội dung) xem `term` đang tìm còn khớp hay không.
            continue

        if action == "y":
            if last_replacement is None:
                print("-> Chưa có từ thay thế nào trước đó để dùng lại bằng '$y'. "
                      "Hãy nhập từ thay thế trước.")
                continue  # hỏi lại đúng chỗ khớp này
            param = last_replacement
            action = "replace"

        if action == "replace":
            if not param:
                print("-> Chưa nhập từ/cụm thay thế. Gõ $help để xem danh sách action.")
                continue
            new_line, n_sub = pattern.subn(param, line)
            lines[idx] = new_line
            last_replacement = param
            stats["changed"] = True
            stats["replaced"] += n_sub
            print(f"-> Đã thay '{term}' -> '{param}' ({n_sub} chỗ trong dòng).")
            idx += 1
            continue

        print(f"-> Không rõ action '${action}'. Gõ $help để xem danh sách action.")


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
        "--ignore-file",
        type=Path,
        default=None,
        help="File lưu danh sách bỏ qua từ '$skip:cụm' "
             "(mặc định: ignore_<tên wordlist>.txt cùng thư mục)",
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
    ignore_path: Path = args.ignore_file or (wl_path.parent / f"ignore_{wl_path.name}")
    ignore_map = load_ignore_map(ignore_path)

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

    stats = {"changed": False, "replaced": 0, "notes": 0, "ignored": 0}

    try:
        for i, term in enumerate(queue):
            remaining_terms = queue[i + 1:]
            try:
                process_term(
                    term, lines, pending_path, args.ignore_case, use_color,
                    stats, remaining_terms=remaining_terms,
                    ignore_map=ignore_map, ignore_path=ignore_path,
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
        if stats["ignored"]:
            print(f"Đã thêm {stats['ignored']} cụm vào danh sách bỏ qua: {ignore_path}")

        print(f"Tổng số lượt thay thế: {stats['replaced']}")


if __name__ == "__main__":
    main()
