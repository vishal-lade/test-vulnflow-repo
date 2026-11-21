# 🛡️ VulnFlow Test Repository

This repository is an intentional security testbed designed to test **[VulnFlow AI](https://github.com/lade6501/VulnFlow)** (Autonomous Agentic Vulnerability Remediation Platform).

> [!WARNING]  
> **INTENTIONALLY VULNERABLE CODE**: This repository contains synthetic vulnerabilities, mock PII, and dummy secrets for testing security scanners and automated remediation tools. **DO NOT USE ANY OF THIS CODE IN PRODUCTION.**

---

## 🎯 Test Objective

The primary objective of this repository is to test VulnFlow when **no pre-existing scanner report** is checked in:
- VulnFlow directly inspects repository source files, dependencies, secrets, and PII.
- It identifies root-cause dependencies, secret leaks, and security weaknesses.
- It plans safe remediation upgrades, evaluates policies, verifies sandbox builds, and generates reports or opens pull requests.

---

## 📂 Repository Contents

### 1. Code Flaws, Secrets & PII
- **`javascript_sast_vulnerabilities.js`**: Node.js/Express server containing:
  - **Hardcoded AWS Secret**: `AKIAIOSFODNN7EXAMPLE`
  - **Exposed Customer PII**: Social Security Number (`000-12-3456`)
  - **SAST Flaws**: Unsafe SQL query concatenation, child_process command injection, path traversal (`sendFile`), reflected XSS, `eval()`, weak MD5 hashing, unvalidated redirects.
- **`python_sast_vulnerabilities.py`**: Python/Flask application containing:
  - **Hardcoded API Keys & Webhooks**: OpenAI-style test API keys, database credentials, Slack webhook URL.
  - **Exposed PII**: Customer email, phone number, and SSN.
  - **SAST Flaws**: SQL injection, `os.system` command injection, unvalidated file path reads, insecure `pickle.loads` deserialization, weak MD5 password hashing, `eval()`, `subprocess.check_output(shell=True)`.
- **`python_additional_vulnerabilities.py`**: Advanced Python vulnerabilities:
  - **Exposed PII**: Dummy credit card numbers and CVV.
  - **SAST Flaws**: XML External Entity (XXE), `yaml.load()` unsafe loading, LDAP injection, weak DES/ARC2 ciphers, insecure JWT (`none` algorithm), SSRF, TOCTOU race condition.
- **`app.py`**: Entrypoint serving the Flask application.

### 2. Vulnerable Dependencies (SCA)
- **`requirements.txt`**: Outdated Python packages with known high/critical CVEs:
  - `Django==2.2.0`, `Flask==0.12.2`, `requests==2.6.0`, `PyYAML==5.1`, `Jinja2==2.10`, `Pillow==6.0.0`, `cryptography==2.3`, `SQLAlchemy==1.2.0`, `Werkzeug==0.14.0`, `urllib3==1.24`, etc.
- **`package.json`**: Outdated Node.js dependencies with known CVEs (`express`, `lodash`, `mysql`, `mongoose`, `axios`, `marked`, `jsonwebtoken`, etc.) and a verification test script (`npm test`) to simulate sandbox checks.

### 3. Infrastructure as Code (IaC) Misconfigurations
- **`Dockerfile`**: Outdated base image, running as root, exposed sensitive ports, unpinned dependencies, embedded secrets.
- **`docker-compose.yml`**: Services with unauthenticated databases, exposed debug ports, and unrestricted network modes.
- **`kubernetes-deployment.yaml`**: Privileged containers, hostPath volume mounts, cluster-admin role bindings, missing resource limits.
- **`terraform-main.tf`**: Public S3 buckets, open 0.0.0.0/0 security groups, unencrypted databases, hardcoded AWS keys.

---

## 🚀 GitHub Actions CI/CD Pipeline

The workflow file is located at [`.github/workflows/vulnflow.yml`](.github/workflows/vulnflow.yml).

### What the Pipeline Does
1. Checks out the repository.
2. Authenticates to GitHub Container Registry (`ghcr.io`).
3. Pulls the latest VulnFlow container (`ghcr.io/lade6501/vulnflow:latest`).
4. Executes VulnFlow directly against the repository code:
   ```bash
   docker run --rm \
     -v ${{ github.workspace }}:/repo \
     -e GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} \
     -e NVIDIA_API_KEY=${{ secrets.NVIDIA_API_KEY }} \
     ghcr.io/lade6501/vulnflow:latest \
     scan --repo /repo --mode report
   ```
5. Publishes the generated executive markdown remediation report to **GitHub Step Summary**.
6. Uploads audit logs and markdown/JSON reports as build artifacts.

### Repository Secrets & Variables

To customize execution in GitHub Actions, configure the following in your repository's **Settings > Secrets and variables > Actions**:

| Name | Type | Purpose |
|---|---|---|
| `NVIDIA_API_KEY` | Secret | *(Optional)* LLM API key for AI reasoning and planning. If omitted, VulnFlow automatically uses its fast, deterministic rule-based planner (`--no-llm`). |
| `GHCR_PAT` | Secret | *(Optional)* GitHub Personal Access Token with `read:packages` scope if the VulnFlow container package is hosted privately in another GitHub account. |
| `VULNFLOW_IMAGE` | Variable | *(Optional)* Override the container image tag (default: `ghcr.io/lade6501/vulnflow:latest`). |

### Manual Execution (Workflow Dispatch)
You can trigger the pipeline manually under the **Actions** tab with configurable inputs:
- **`mode`**: `report` (read-only audit), `pr` (remediate and open Pull Requests), or `dry-run` (patch and test locally).
- **`auto_approve`**: Auto-approve review-tier remediation plans (e.g. major bumps or secrets).
- **`no_llm`**: Force fast deterministic planning without calling external LLM providers.
- **`image`**: Specify an alternative container image tag.

---

## 💻 Running VulnFlow Container Locally

You can test the published VulnFlow container on this repository locally using Docker:

```bash
# 1. Pull the container from GHCR
docker pull ghcr.io/lade6501/vulnflow:latest

# 2. Run read-only security assessment
docker run --rm \
  -v "$(pwd)":/repo \
  ghcr.io/lade6501/vulnflow:latest \
  scan --repo /repo --mode report --no-llm

# 3. View the generated report
cat .vulnflow/reports/report_*.md
```
