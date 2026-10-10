# AWS EC2 Deployment & Automation Guide

This guide covers provisioning and deploying the **Nazra (نظرة)** Arabic Sentiment MLOps platform on an AWS EC2 instance using the automated provisioning script [`EC2_instance_setup.sh`](../EC2_instance_setup.sh).

---

## ⚡ What the Setup Script Automates

The single-command setup script automates end-to-end environment preparation on Ubuntu, Debian, Amazon Linux, and RHEL:

1. **Docker Engine & Compose:** Installs official Docker CE and Docker Compose plugin.
2. **Swap Memory (2GB):** Configures swap space to prevent Out-Of-Memory (OOM) errors during Docker builds on small or burstable instances (`t2.micro`, `t3.small`, `t3.medium`).
3. **Python Tooling:** Installs Astral `uv` for fast dependency and script execution.
4. **Full Stack Startup:** Clones or updates the repository and brings up all containers in detached mode (`docker compose up -d --build`).
5. **Network Output:** Automatically detects the EC2 public IP and outputs direct URLs for all running services.

---

## 🚀 Running the Setup Script

### Option A: Run Directly on the EC2 Instance
SSH into your instance and run:
```bash
curl -fsSL https://raw.githubusercontent.com/Yossef-moftah-dev/arabic-sentiment-arabert/main/EC2_instance_setup.sh | bash
```

### Option B: Run Remotely from Your Local Machine
From your local machine, stream the script into the EC2 SSH session:
```bash
ssh -i <path/to/your-key.pem> ubuntu@<EC2_PUBLIC_DNS> "bash -s" < EC2_instance_setup.sh
```

---

## 🌐 Accessing Remote Services

### Method 1: Direct Access via Public IP
Configure your AWS Security Group with inbound TCP rules for the following ports:
- **`8000`**: BentoML / FastAPI inference & Swagger UI (`http://<EC2_PUBLIC_IP>:8000/docs`)
- **`5000`**: MLflow UI (`http://<EC2_PUBLIC_IP>:5000`)
- **`3000`**: Grafana Dashboards (`http://<EC2_PUBLIC_IP>:3000`)
- **`9001`**: MinIO Console (`http://<EC2_PUBLIC_IP>:9001`)

### Method 2: Encrypted SSH Tunneling
If you prefer keeping security group ports closed to the public internet, use the included tunneling helper:
```bash
./scripts/tunnel_services.sh <path/to/your-key.pem> <EC2_PUBLIC_DNS>
```
This securely forwards remote ports to your local machine:
- `http://localhost:8000` (API)
- `http://localhost:5000` (MLflow)
- `http://localhost:9001` (MinIO)
- `http://localhost:9000` (S3 API)

---

## 🔬 Populating MLflow Experiments on EC2

To run the model exploration matrix (5 runs comparing AraBERT, CAMeLBERT, and MARBERT) and register the champion model directly inside the remote MLflow database:

```bash
ssh -i <path/to/your-key.pem> ubuntu@<EC2_PUBLIC_DNS> \
  "cd ~/arabic-sentiment-arabert && uv run python scripts/run_experiments.py"
```
