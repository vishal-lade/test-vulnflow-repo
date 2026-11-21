"""
app.py
Main entrypoint for vulnerable test application.
Imports vulnerable routes from python_sast_vulnerabilities.py and runs the server.
"""

from python_sast_vulnerabilities import app

if __name__ == "__main__":
    # Intentionally running with debug=True in demo/test environment
    app.run(host="0.0.0.0", port=5000, debug=True)
