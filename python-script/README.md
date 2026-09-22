
# generate-count-sql.py

Script sinh SQL `COUNT(*)` cho **ClickHouse table** hoặc **Delta table trên S3**.

## Cách dùng

```bash
python generate-count-sql.py <input1> <input2> ...
```

* Không có `/` → ClickHouse table
* Có `/` → S3 path
* Có thể nhập cả hai loại cùng lúc.

### Ví dụ

```bash
python generate-count-sql.py \
  mart__internal__vhm_self_bi.vhm_sap__house_area \
  mart__internal__vhm_self_bi.vhm_sap__house_price \
  mart/vhm/house_area
```

## Output

SQL được in ra terminal và lưu vào:

```text
/tmp/generate_sql_<timestamp>.sql
```

Không cần cài thêm package, yêu cầu Python 3.9+.
