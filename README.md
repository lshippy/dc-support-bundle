# System & Docker Compose Support Bundle Script

This script collects **system information**, **Docker Compose project details**, and **logs** into a structured support bundle for debugging and analysis. It automatically gathers relevant system and Docker data and zips the results into a single archive.

---

## 📌 Features
- Collects **system details**:
  - Hostname, OS, IP address, kernel version, uptime.
  - Memory usage, disk usage.
  - Top CPU/memory-consuming processes.
- Fetches **Docker and Docker Compose versions**.
- Inspects **Docker system storage usage**.
- Detects **active Docker Compose projects** and collects:
  - `docker-compose.yml` and `.env` files (with sensitive values redacted).
  - Status of all containers (`docker compose ps -a`).
  - Logs from **all profiles** (`docker compose --profile "*" logs --timestamps`).
- Saves all collected information into a compressed ZIP file.

---

## 📂 Output Structure

The script generates a zip file containing:

```
support_bundle_<hostname>_<timestamp>.zip
│── system_report.txt               # General system info
│── compose_configs/                 # Docker Compose configurations
│   ├── <project_name>/
│   │   ├── docker-compose.yml       # Compose file
│   │   ├── <project_name>.env       # Redacted .env file
│   │   ├── <project_name>_status.txt # Container statuses
│── compose_logs/                     # Docker Compose logs
│   ├── <project_name>_logs.txt       # Service logs with timestamps
```

---

## 🛠️ Requirements

Ensure the following are installed on the system:

- `jq` (for JSON parsing)
- `zip` (for compressing the support bundle)

To install missing dependencies:

```bash
sudo apt install jq zip -y   # Debian/Ubuntu
sudo yum install jq zip -y   # CentOS/RHEL
```

---

## 🚀 Usage

Simply run the script:

```bash
./support_bundle.sh
```

or specify a log duration (default is `2h`):

```bash
./support_bundle.sh 4h  # Collect logs from the last 4 hours
```

---

## 📝 How It Works

1. **System Information Collection**  
   - Retrieves details such as hostname, OS, IP address, memory usage, disk usage, CPU/memory-consuming processes.
   - Outputs to `system_report.txt`.

2. **Docker Compose Detection**  
   - Uses `docker compose ls --format json` to identify running Compose projects.
   - Extracts `docker-compose.yml` and `.env` files.
   - Redacts sensitive information from `.env`.

3. **Log & Status Collection**  
   - Runs `docker compose ps -a` to fetch the container status.
   - Runs `docker compose --profile "*" logs --timestamps --since <LOG_DURATION>` to gather logs.
   - Saves logs per project.

4. **Compression & Cleanup**  
   - Archives all collected files into a zip archive.
   - Removes temporary files after completion.

---

## ⚠️ Troubleshooting

### **1. Error: `jq: command not found`**
   - Install `jq` using:  
     ```bash
     sudo apt install jq -y   # Debian/Ubuntu
     sudo yum install jq -y   # CentOS/RHEL
     ```

### **2. Warning: `No logs found for <project>`**
   - Check if the container has logs using:  
     ```bash
     docker compose --profile "*" logs --timestamps --since 2h
     ```

### **3. `Permission denied` errors**
   - Run the script with `sudo`:
     ```bash
     sudo ./support_bundle.sh
     ```

---

## 📦 Example Output

```plaintext
Collecting system information...
Detecting active Docker Compose projects...
Found project 'c4r' with config file '/home/ubuntu/c4r/docker-compose.yml'
Processing Compose project: c4r at /home/ubuntu/c4r
Redacting sensitive info in .env file for c4r
Collecting Docker Compose status for c4r
Collecting logs for c4r
Logs successfully collected for c4r
Zipping all collected information...
  adding: support_bundle_concentriq-AIO_2025_02_26/ (stored 0%)
  adding: support_bundle_concentriq-AIO_2025_02_26/system_report.txt (deflated 61%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_configs/ (stored 0%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_configs/c4r/ (stored 0%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_configs/c4r/c4r.env (deflated 45%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_configs/c4r/docker-compose.yml (deflated 75%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_configs/c4r/c4r_status.txt (deflated 80%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_logs/ (stored 0%)
  adding: support_bundle_concentriq-AIO_2025_02_26/compose_logs/c4r_logs.txt (deflated 88%)
Done! Support bundle saved as support_bundle_concentriq-AIO_2025_02_26.zip
```
