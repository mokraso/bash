
# Claude Code Docker

Docker environment chạy **Ubuntu 24.04 + Node.js 22 + npm + Git + Claude Code**.

## 1. Start container

Build image và start container:

```bash
docker compose up -d --build
```

Nếu image đã được build trước đó:

```bash
docker compose up -d
```

Kiểm tra container:

```bash
docker compose ps
```

## 2. Exec vào container

Vào shell của container:

```bash
docker compose exec claude bash
```

Sau khi vào container:

```bash
claude
```

## 3. Kiểm tra môi trường

Trong container:

```bash
node --version
npm --version
git --version
claude --version
```

## 4. Stop container

```bash
docker compose down
```

Nếu chỉ muốn stop mà không xóa container:

```bash
docker compose stop
```

Start lại:

```bash
docker compose start
```

## 5. Rebuild image

Khi thay đổi `Dockerfile`:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

Hoặc ngắn gọn:

```bash
docker compose up -d --build
```

## 6. Mount source code

Các thư mục trên host được khai báo trong `compose.yaml` sẽ được mount vào container.

Ví dụ:

```yaml
volumes:
  - /home/laidq/projects:/workspace
```

Khi đó:

```text
Host:
  /home/laidq/projects

Container:
  /workspace
```

Trong container:

```bash
cd /workspace
ls
```

sẽ thấy toàn bộ source code từ host.

## 7. Workflow hằng ngày

Thông thường chỉ cần:

```bash
docker compose up -d
docker compose exec claude bash
```

Sau đó:

```bash
cd /workspace
claude
```

## 8. Check container status

```bash
docker compose ps
```

Xem log:

```bash
docker compose logs claude
```

Theo dõi log realtime:

```bash
docker compose logs -f claude
```
