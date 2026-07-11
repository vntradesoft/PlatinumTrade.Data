# PlatinumTrade.Data

English | **Tiếng Việt** (bản đang xem)
- [English version (Bản tiếng Anh)](README.md)

Kho lưu trữ và phân phối dữ liệu lịch sử nến (Candlestick History Data) dành cho dự án **PlatinumTrade**.

Repository này chứa tệp cấu hình `manifest.json` tổng điều hướng tải xuống và các tệp dữ liệu dạng nén `.zip` chứa lịch sử nến nhị phân của từng Symbol.

---

## 📂 Các tập lệnh tự động hóa

Repository cung cấp hai tập lệnh PowerShell để tự động hóa quy trình đóng gói dữ liệu và đẩy lên GitHub:

### 1. Tập lệnh chính: `sync-data.ps1`
Tập lệnh đa năng giúp tự động hóa toàn bộ quy trình: quét dữ liệu từ máy cục bộ, đóng gói ZIP, tạo/cập nhật `manifest.json` tổng, đồng bộ hóa Git và đẩy trực tiếp lên GitHub Releases.

### 2. Tập lệnh phím tắt: `sync-btc-eth.ps1`
Tập lệnh phím tắt được thiết kế riêng để **chỉ tải lên và đồng bộ nhanh 2 Symbol: `BTC-USDT-SWAP` và `ETH-USDT-SWAP`**.
*   Tập lệnh này gọi trực tiếp tập lệnh chính `sync-data.ps1` và truyền sẵn các tham số cấu hình sẵn.
*   Bạn chỉ cần chọn loại dữ liệu (`demo` hoặc `real`) và script sẽ tự động thực hiện mọi thứ mà không cần nhập thêm bất kỳ thông tin nào khác.

---

## 🛠 Hướng dẫn thiết lập ban đầu (Prerequisites)

Để tiến trình tự động hóa chạy trơn tru, bạn cần cấu hình một số công cụ dưới đây một lần duy nhất:

### 1. Cài đặt và đăng nhập GitHub CLI (`gh`)
*   **Cài đặt:** Mở PowerShell chạy lệnh:
    ```powershell
    winget install --id GitHub.cli
    ```
    *(Khởi động lại PowerShell sau khi cài đặt)*
*   **Xác thực tài khoản (Yêu cầu tài khoản có quyền Write/Owner đối với repo này):**
    ```powershell
    gh auth login
    ```
    Chọn **GitHub.com** -> Chọn **HTTPS** -> Chọn **Yes** để đồng bộ Git credentials -> Chọn **Login with a web browser** và nhập mã OTP xuất hiện trên màn hình vào trình duyệt để xác thực.

### 2. Thiết lập Git Remote cho thư mục cục bộ
Nếu thư mục chứa script chưa được thiết lập kết nối tới GitHub, hãy chạy các lệnh sau để khởi tạo và liên kết:
```powershell
git init
git remote add origin https://github.com/vntradesoft/PlatinumTrade.Data.git
git branch -M main
```

> ⚠️ **Lưu ý sửa lỗi Git Push (Rejected):**
> Nếu lệnh đẩy Git bị từ chối do lịch sử không đồng nhất với GitHub (lần đầu tiên chạy sau khi khởi tạo `git init`), hãy chạy lệnh sau để kéo code cũ về trước khi đẩy:
> ```powershell
> git pull origin main --allow-unrelated-histories --rebase
> git push origin main
> ```

---

## 🚀 Hướng dẫn sử dụng tập lệnh

Mở PowerShell tại thư mục này và sử dụng một trong các cách chạy sau:

### Cách 1: Đồng bộ nhanh BTC & ETH (Khuyên dùng khi cập nhật dữ liệu chính)
Chạy tập lệnh phím tắt để đồng bộ nhanh 2 symbols này lên GitHub Release:
```powershell
powershell -ExecutionPolicy Bypass -File .\sync-btc-eth.ps1
```

### Cách 2: Chạy tương tác tập lệnh chính (Interactive Mode)
Chạy tập lệnh chính và nhập các tùy chọn theo hướng dẫn trực quan trên màn hình để cấu hình chi tiết:
```powershell
powershell -ExecutionPolicy Bypass -File .\sync-data.ps1
```

### Cách 3: Chạy tự động hoàn toàn (Automated / Non-Interactive Mode)
Sử dụng các tham số dòng lệnh để chạy ngầm hoặc tích hợp CI/CD mà không cần nhập liệu thủ công:

*   **Tải lên tất cả dữ liệu Demo của các Symbol, tự động commit và đẩy lên Release `datasets-v1`:**
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\sync-data.ps1 -Datatype demo -Symbols * -GitSync -ReleaseUpload -TagName datasets-v1
    ```
*   **Chỉ đóng gói và đồng bộ riêng một số Symbol cụ thể (ví dụ BTC và ETH):**
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\sync-data.ps1 -Datatype demo -Symbols "BTC-USDT-SWAP,ETH-USDT-SWAP" -GitSync -ReleaseUpload
    ```

---

## 📝 Chi tiết các tham số của `sync-data.ps1`

| Tham số | Kiểu dữ liệu | Giá trị mặc định | Mô tả |
| :--- | :--- | :--- | :--- |
| `-Datatype` | `string` | Không (sẽ hỏi) | Loại dữ liệu nguồn: `"demo"` hoặc `"real"`. |
| `-Symbols` | `string` | Không (sẽ hỏi) | Danh sách Symbol cần xử lý (ví dụ: `"BTC-USDT-SWAP,ETH-USDT-SWAP"`), nhập chỉ số thứ tự, hoặc `"*"` để chọn tất cả. |
| `-GitSync` | `switch` | Không (sẽ hỏi) | Bật tự động commit và push tệp `manifest.json` tổng lên Git. |
| `-ReleaseUpload`| `switch` | Không (sẽ hỏi) | Bật tự động tải các file ZIP dữ liệu lên GitHub Releases làm tài nguyên tải về. |
| `-TagName` | `string` | `"datasets-v1"` | Thẻ định danh Release trên GitHub (nơi lưu trữ các file ZIP tải về). |
