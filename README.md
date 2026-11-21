# 🛡️ VulnFlow Test Repository

This repository is an intentional security testbed designed to test **[VulnFlow AI](https://github.com/lade6501/VulnFlow)** (Autonomous Agentic Vulnerability Remediation Platform).

> [!WARNING]  
> **INTENTIONALLY VULNERABLE CODE**: This repository contains synthetic vulnerabilities, mock PII, and dummy secrets for testing security scanners and automated remediation tools. **DO NOT USE ANY OF THIS CODE IN PRODUCTION.**

---

## 🎯 Test Objective

The primary objective of this repository is to test VulnFlow when **no pre-existing scanner report** is checked in:
- VulnFlow directly inspects repository source files, dependencies, secrets, and PII.
- It evaluates organizational package governance policies defined in [`policies/approved_packages.yaml`](policies/approved_packages.yaml).
- When a package is unknown, deprecated, or a leaked secret/PII is detected, it pauses execution at the **Human Approval Gate** (`Exit Code: 10`), waiting for approval before creating Pull Requests.
- It plans safe remediation upgrades, verifies sandbox builds, and generates reports or opens pull requests once approved.

---

## 📂 Repository Contents

### 1. Code Flaws, Secrets & PII
- **`javascript_sast_vulnerabilities.js`**: Node.js/Express server containing:
  - **Hardcoded AWS Secret**: `AKIAIOSFODNN7EXAMPLE`
  - **Exposed Customer PII**: Social Security Number (`000-12-3456`)
  - **SAST Flaws**: Unsafe SQL query concatenation, `child_process.exec` command injection, path traversal (`sendFile`), reflected XSS, `eval()`, weak MD5 hashing, unvalidated redirects.
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

### 3. Governance Policy
- **[`policies/approved_packages.yaml`](policies/approved_packages.yaml)**: Defines:
  - Approved packages and version constraints (`lodash >= 4.17.21`, `express >= 4.19.2`, `requests >= 2.32.0`, `flask >= 2.3.0`, etc.).
  - Deprecated packages (e.g. `moment` -> replace with `date-fns`).
  - Banned packages (e.g. `left-pad`).
  - Strict governance rules: `unknown_package: require_approval` forces review-tier pause on unvetted packages.

---

## 🚀 GitHub Actions CI/CD Pipelines

### Pipeline 1: Scan & Remediate ([`.github/workflows/vulnflow.yml`](.github/workflows/vulnflow.yml))
Automatically runs on `push`, `pull_request`, or manual `workflow_dispatch`:
1. Checks out repository code.
2. Pulls the latest VulnFlow container from GitHub Container Registry (`ghcr.io/lade6501/vulnflow:latest`).
3. Executes VulnFlow directly against the repository code without any pre-existing report.
4. If a review-tier plan is generated (e.g. major bump, unvetted package, secret rotation), execution pauses with `Exit Code: 10` and outputs the Plan ID(s).
5. Publishes the executive Markdown remediation report to **GitHub Step Summary**.
6. Uploads audit logs and markdown/JSON reports as build artifacts.

### Pipeline 2: Approval Workflow ([`.github/workflows/approve.yml`](.github/workflows/approve.yml))
Triggered manually under the **Actions** tab to authorize or reject paused plans:
- **`plan_id`**: The Plan ID reported by VulnFlow (e.g. `PLAN-ebaaef6720e2`).
- **`action`**: `approve` or `reject`.
- **`reason`**: Reviewer justification.
- **`resume`**: `true` to immediately resume execution and open the Pull Request.

---

## 💻 Running VulnFlow Locally with Docker

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

# 4. Authorize a review-tier plan locally
docker run --rm \
  -v "$(pwd)":/repo \
  ghcr.io/lade6501/vulnflow:latest \
  approve --plan-id <PLAN-ID> --resume --repo /repo --reviewer "security-lead"
```
