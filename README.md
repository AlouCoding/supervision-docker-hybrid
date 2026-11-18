# 🛡️ Hybrid Network Monitoring & Multi-Channel Alerting Stack

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Nagios](https://img.shields.io/badge/Nagios_Core-000000?style=for-the-badge&logo=nagios&logoColor=white)](https://www.nagios.org/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Bash](https://img.shields.io/badge/Bash_Scripting-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

An end-to-end, containerized **Hybrid IT Infrastructure Monitoring and Real-Time Alerting** solution built with Docker Compose. This project combines **Nagios Core** for active availability probing and network topology mapping with **Prometheus & Grafana** for real-time time-series metrics and SLA visualization.

---

## 🎯 Key Features

* **Hybrid Observability Architecture:** Combines active state checks (`SOFT`/`HARD` state confirmation, parent-child network dependencies) with pull-based metrics scraping (`15s` intervals).
* **Multi-Channel Real-Time Alerting:** Custom Bash notification engine (`notify.sh`) triggered on host/service `PROBLEM` and `RECOVERY` events across three simultaneous channels:
  * 📱 **WhatsApp** via REST API (`GREEN-API`)
  * ✈️ **Telegram** via official Bot API (`HTML` formatted alerts)
  * 📧 **Email** via `SMTPS` (Gmail) & local testing (`MailHog`)
* **Network Dependency Mapping:** Parent-child relationship modeling (`routeur` $\rightarrow$ `srvalou` & `clalou`) to distinguish between `DOWN` and `UNREACHABLE` states and prevent alert storms.
* **One-Command Reproducible Deployment:** Fully isolated 10-container microservices architecture orchestrated via `docker-compose`.

---

## 🏗️ System Architecture

```text
                        +---------------------------------------+
                        |       MONITORING & ALERTING STACK     |
                        |                                       |
+---------------+       |  +-------------+     +-------------+  |      +-------------------+
|    routeur    |<------|  | Nagios Core |---->|  notify.sh  |--|----->| WhatsApp (API)    |
| (Gateway)     |       |  | (Probes/Map)|     | (Alert Bot) |--|----->| Telegram (Bot)    |
+-------+-------+       |  +-------------+     +-------------+  |----->| Email (SMTPS)     |
        |               |                                       |      +-------------------+
        +---------------+  +-------------+     +-------------+  |
        |               |  | Prometheus  |---->|   Grafana   |  |
        v               |  | (TSDB Pull) |     | (Dashboards)|  |
+-------+-------+       |  +------+------+     +-------------+  |
|    srvalou    |<------|         |                             |
| (DNS Bind9)   |       |  +------+------+                      |
+---------------+       |  |  Exporters  | (Blackbox, Node,     |
        |               |  |             |  cAdvisor)           |
        v               |  +-------------+                      |
+-------+-------+       +---------------------------------------+
|    clalou     |
| (Web Nginx)   |
+---------------+
```

### Container Stack Breakdown
| Service | Role | Port |
| :--- | :--- | :--- |
| **Nagios Core** | Active host/service probing, network topology map, alert trigger | `8080` |
| **Prometheus** | Time-series database scraping metrics every 15s | `9090` |
| **Grafana** | Real-time availability dashboards, latency & resource graphs | `3000` |
| **Blackbox Exporter** | TCP port probing (`DNS :53`, `HTTP :80`) for Prometheus | `9115` |
| **Node Exporter** | Host system metrics (CPU, RAM, Disk I/O) | `9100` |
| **cAdvisor** | Docker container resource usage & performance metrics | `8081` |
| **MailHog** | Local SMTP sink for safe email alert testing | `8025` |
| **Target Nodes** | Simulated infrastructure (`routeur`, `srvalou` Bind9, `clalou` Nginx) | Internal DNS |

---

## 🚀 Quick Start

### Prerequisites
* [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/) installed.
* API credentials for notification channels (optional for local MailHog testing).

### Installation & Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/hybrid-network-monitoring.git
   cd hybrid-network-monitoring
   ```

2. **Configure environment variables**
   Copy the example environment file and add your API tokens (never commit real secrets to version control):
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your credentials:
   ```env
   # WhatsApp (GREEN-API)
   GREEN_API_INSTANCE_ID=your_instance_id
   GREEN_API_TOKEN=your_api_token
   WHATSAPP_TARGET_PHONE=221770000000@c.us

   # Telegram Bot API
   TELEGRAM_BOT_TOKEN=your_bot_token
   TELEGRAM_CHAT_ID=your_chat_id

   # Email (Gmail SMTPS)
   SMTP_EMAIL=your_email@gmail.com
   SMTP_APP_PASSWORD=your_16_char_app_password
   ```

3. **Launch the entire stack**
   ```bash
   docker compose up -d
   ```

4. **Access the interfaces**
   * **Nagios Core:** `http://localhost:8080`
   * **Grafana:** `http://localhost:3000`
   * **Prometheus:** `http://localhost:9090`
   * **MailHog:** `http://localhost:8025`

---

## 🧪 Live Failure Simulation (Demo Scenario)

To test the end-to-end detection and alerting pipeline:

1. **Simulate an outage** on the DNS server (`srvalou`):
   ```bash
   docker stop srvalou
   ```
2. **Observe real-time detection:**
   * Within **15s**, Grafana availability tiles turn red (`HORS SERVICE`).
   * Within **~90s** (after 2 failed Nagios checks: `SOFT` $\rightarrow$ `HARD`), the Nagios topology map updates and `notify.sh` dispatches critical alerts simultaneously to **WhatsApp, Telegram, and Email**.
3. **Restore the service:**
   ```bash
   docker start srvalou
   ```
   * Automated `RECOVERY` notifications are sent across all three channels once the host is back online.

---

## 📸 Screenshots & Alert Previews

> *Tip: Replace these placeholders with your actual screenshots in a `/docs/images/` folder.*

| Multi-Channel Alert (WhatsApp / Telegram / Email) | Grafana Real-Time Dashboard |
| :---: | :---: |
| ![Alert Preview](docs/images/alert_preview.png) | ![Grafana Dashboard](docs/images/grafana_dashboard.png) |

---

## 🔒 Security & Engineering Best Practices

* **Secret Management:** All API keys and SMTP app passwords are decoupled from the notification script (`notify.sh`) via environment variables / Docker secrets.
* **Noise Reduction:** Configured `max_check_attempts 2` and parent-child topology dependencies to eliminate false positives during transient network spikes.

---

## 👨‍💻 Author

**Alassane NDOUR**  
*Master 2 in Distributed Information Systems (SIR) — Cheikh Anta Diop University (UCAD), Dakar*  
*Focus: Cloud Infrastructure, DevOps/MLOps, Container Orchestration & Observability*

* 🔗 **LinkedIn:** [linkedin.com/in/your-profile](https://linkedin.com)
* 🐙 **GitHub:** [github.com/your-username](https://github.com)