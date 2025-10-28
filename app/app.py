from flask import Flask, request, render_template_string
import os

app = Flask(__name__)

# HTML template for displaying IP information
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IP Address Display</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
        }
        .ip-info {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin: 15px 0;
            border-left: 4px solid #007bff;
        }
        .ip-label {
            font-weight: bold;
            color: #495057;
            margin-bottom: 5px;
        }
        .ip-value {
            font-family: monospace;
            font-size: 18px;
            color: #007bff;
            word-break: break-all;
        }
        .timestamp {
            text-align: center;
            color: #6c757d;
            font-size: 14px;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 IP Address Information</h1>
        
        <div class="ip-info">
            <div class="ip-label">Client Original IP (X-Forwarded-For):</div>
            <div class="ip-value">{{ client_ip }}</div>
        </div>
        
        <div class="ip-info">
            <div class="ip-label">Direct Connecting IP:</div>
            <div class="ip-value">{{ direct_ip }}</div>
        </div>
        
        <div class="timestamp">
            Requested at: {{ timestamp }}
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    # Get client's original IP from X-Forwarded-For header (CloudFront)
    client_ip = request.headers.get('X-Forwarded-For', 'Not available')
    
    # Get direct connecting IP
    direct_ip = request.remote_addr
    
    # Get current timestamp
    from datetime import datetime
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
    
    return render_template_string(HTML_TEMPLATE, 
                                client_ip=client_ip,
                                direct_ip=direct_ip,
                                timestamp=timestamp)

@app.route('/health')
def health():
    """Health check endpoint for ALB"""
    return {'status': 'healthy', 'service': 'ip-display-app'}, 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
