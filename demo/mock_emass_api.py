#!/usr/bin/env python3
"""
Mock eMASS API Server for Demo
Provides realistic POA&M data for demonstration purposes
"""

from flask import Flask, jsonify, request
import json

app = Flask(__name__)

# Sample POA&M data
SAMPLE_POAMS = [
    {
        "poamId": 12345,
        "systemId": 55090,
        "displayPoamId": "POA-2024-001",
        "status": "Ongoing",
        "vulnerabilityDescription": "Unpatched Apache Tomcat vulnerability CVE-2024-12345",
        "sourceIdentVuln": "CVE-2024-12345",
        "pocOrganization": "IT Security Team",
        "resources": "Security Team - 40hrs, System Admin - 20hrs",
        "scheduledCompletionDate": "2024-12-31",
        "milestones": [
            {
                "milestoneId": 1,
                "description": "Patch testing in dev environment",
                "scheduledCompletionDate": "2024-11-15"
            },
            {
                "milestoneId": 2,
                "description": "Production deployment",
                "scheduledCompletionDate": "2024-12-15"
            }
        ],
        "severity": "High",
        "relevanceOfThreat": "Very High",
        "likelihood": "High",
        "impact": "High",
        "rawSeverity": "III"
    },
    {
        "poamId": 12346,
        "systemId": 55090,
        "displayPoamId": "POA-2024-002",
        "status": "Risk Accepted",
        "vulnerabilityDescription": "Legacy authentication mechanism in use",
        "sourceIdentVuln": "AUDIT-2024-002",
        "pocOrganization": "Application Development",
        "resources": "Dev Team - 120hrs",
        "scheduledCompletionDate": "2025-03-31",
        "milestones": [
            {
                "milestoneId": 1,
                "description": "OAuth 2.0 implementation",
                "scheduledCompletionDate": "2025-02-28"
            }
        ],
        "severity": "Medium",
        "relevanceOfThreat": "Medium",
        "likelihood": "Medium",
        "impact": "Medium",
        "rawSeverity": "II"
    },
    {
        "poamId": 12347,
        "systemId": 55090,
        "displayPoamId": "POA-2024-003",
        "status": "Completed",
        "vulnerabilityDescription": "Missing SSL/TLS on internal endpoints",
        "sourceIdentVuln": "SCAN-2024-045",
        "pocOrganization": "Network Security",
        "resources": "Network Team - 16hrs",
        "scheduledCompletionDate": "2024-10-31",
        "milestones": [],
        "severity": "High",
        "relevanceOfThreat": "High",
        "likelihood": "Medium",
        "impact": "High",
        "rawSeverity": "III"
    }
]


@app.route('/api/systems/<int:system_id>/poams', methods=['GET'])
def get_poams(system_id):
    """Get POA&Ms for a specific system"""
    # Verify API key
    api_key = request.headers.get('api-key')
    if not api_key:
        return jsonify({"error": "Missing api-key header"}), 401

    # Filter POA&Ms by system ID
    filtered_poams = [p for p in SAMPLE_POAMS if p['systemId'] == system_id]

    return jsonify(filtered_poams), 200


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "mock-emass-api"}), 200


if __name__ == '__main__':
    print("Starting Mock eMASS API Server...")
    print("Endpoint: http://localhost:4010/api/systems/55090/poams")
    print("API Key: demo-api-key-12345")
    app.run(host='0.0.0.0', port=4010, debug=False)
