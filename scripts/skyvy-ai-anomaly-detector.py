#!/usr/bin/env python3

"""
SkyvyOS AI-Powered Anomaly Detection System

Machine Learning based system monitoring with predictive alerts
Uses scikit-learn for anomaly detection

Requirements:
- python3-pip
- scikit-learn, pandas, numpy

Install: pip3 install scikit-learn pandas numpy psutil
"""

import sys
import json
import time
import psutil
import smtplib
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from collections import deque
import pickle
import os

try:
    import numpy as np
    import pandas as pd
    from sklearn.ensemble import IsolationForest
    from sklearn.preprocessing import StandardScaler
except ImportError:
    print("Error: Required packages not installed")
    print("Install: pip3 install scikit-learn pandas numpy psutil")
    sys.exit(1)

# Configuration
MODEL_FILE = "/var/lib/skyvyos/anomaly_model.pkl"
DATA_FILE = "/var/lib/skyvyos/historical_metrics.csv"
ALERT_EMAIL = "admin@localhost"
THRESHOLD = -0.5  # Anomaly score threshold

class AnomalyDetector:
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.metrics_history = deque(maxlen=1000)
        self.load_model()
    
    def collect_metrics(self):
        """Collect current system metrics"""
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        network = psutil.net_io_counters()
        
        # Process count
        process_count = len(psutil.pids())
        
        # Load average
        load_avg = os.getloadavg()[0]
        
        # Network metrics
        net_sent = network.bytes_sent
        net_recv = network.bytes_recv
        
        # I/O metrics
        io = psutil.disk_io_counters()
        io_read = io.read_bytes
        io_write = io.write_bytes
        
        metrics = {
            'timestamp': datetime.now().isoformat(),
            'cpu_percent': cpu_percent,
            'memory_percent': memory.percent,
            'disk_percent': disk.percent,
            'process_count': process_count,
            'load_avg': load_avg,
            'net_sent_mb': net_sent / (1024**2),
            'net_recv_mb': net_recv / (1024**2),
            'io_read_mb': io_read / (1024**2),
            'io_write_mb': io_write / (1024**2),
        }
        
        return metrics
    
    def train_model(self, data):
        """Train anomaly detection model"""
        print("Training anomaly detection model...")
        
        # Prepare features
        features = ['cpu_percent', 'memory_percent', 'disk_percent', 
                   'process_count', 'load_avg', 'net_sent_mb', 'net_recv_mb',
                   'io_read_mb', 'io_write_mb']
        
        X = data[features].values
        
        # Scale features
        X_scaled = self.scaler.fit_transform(X)
        
        # Train Isolation Forest
        self.model = IsolationForest(
            contamination=0.1,  # Expected anomaly rate
            random_state=42,
            n_estimators=100
        )
        self.model.fit(X_scaled)
        
        # Save model
        with open(MODEL_FILE, 'wb') as f:
            pickle.dump({'model': self.model, 'scaler': self.scaler}, f)
        
        print(f"Model trained and saved to {MODEL_FILE}")
    
    def load_model(self):
        """Load pre-trained model"""
        if os.path.exists(MODEL_FILE):
            with open(MODEL_FILE, 'rb') as f:
                data = pickle.load(f)
                self.model = data['model']
                self.scaler = data['scaler']
            print("Model loaded successfully")
        else:
            print("No pre-trained model found. Will train on first run.")
    
    def detect_anomaly(self, metrics):
        """Detect if current metrics are anomalous"""
        if self.model is None:
            return False, 0.0
        
        features = ['cpu_percent', 'memory_percent', 'disk_percent', 
                   'process_count', 'load_avg', 'net_sent_mb', 'net_recv_mb',
                   'io_read_mb', 'io_write_mb']
        
        X = np.array([[metrics[f] for f in features]])
        X_scaled = self.scaler.transform(X)
        
        # Get anomaly score
        score = self.model.score_samples(X_scaled)[0]
        
        # Predict anomaly (-1 for anomaly, 1 for normal)
        prediction = self.model.predict(X_scaled)[0]
        
        is_anomaly = prediction == -1 or score < THRESHOLD
        
        return is_anomaly, score
    
    def send_alert(self, metrics, score):
        """Send email alert for anomaly"""
        subject = f"SkyvyOS Anomaly Detected: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        
        body = f"""
Anomaly Detection Alert
=======================

Time: {metrics['timestamp']}
Anomaly Score: {score:.4f}

Current Metrics:
- CPU: {metrics['cpu_percent']:.1f}%
- Memory: {metrics['memory_percent']:.1f}%
- Disk: {metrics['disk_percent']:.1f}%
- Processes: {metrics['process_count']}
- Load Average: {metrics['load_avg']:.2f}
- Network Sent: {metrics['net_sent_mb']:.2f} MB
- Network Received: {metrics['net_recv_mb']:.2f} MB

Action Required: Investigate system for unusual activity
        """
        
        msg = MIMEText(body)
        msg['Subject'] = subject
        msg['From'] = 'skyvyos@localhost'
        msg['To'] = ALERT_EMAIL
        
        try:
            s = smtplib.SMTP('localhost')
            s.send_message(msg)
            s.quit()
            print(f"Alert sent to {ALERT_EMAIL}")
        except Exception as e:
            print(f"Failed to send alert: {e}")
        
        # Log to file
        with open('/var/log/skyvyos-anomaly.log', 'a') as f:
            f.write(f"{metrics['timestamp']}: ANOMALY DETECTED (score: {score:.4f})\n")
            f.write(json.dumps(metrics, indent=2) + "\n\n")
    
    def run_continuous(self, interval=60):
        """Run continuous monitoring"""
        print(f"Starting continuous anomaly detection (checking every {interval}s)")
        print("Press Ctrl+C to stop")
        
        try:
            while True:
                metrics = self.collect_metrics()
                self.metrics_history.append(metrics)
                
                # Save metrics to CSV
                df = pd.DataFrame(list(self.metrics_history))
                df.to_csv(DATA_FILE, index=False)
                
                # Train model if not exists and we have enough data
                if self.model is None and len(self.metrics_history) >= 100:
                    self.train_model(df)
                
                # Detect anomaly
                if self.model is not None:
                    is_anomaly, score = self.detect_anomaly(metrics)
                    
                    if is_anomaly:
                        print(f"⚠️  ANOMALY DETECTED! Score: {score:.4f}")
                        self.send_alert(metrics, score)
                    else:
                        print(f"✓ Normal operation (score: {score:.4f})")
                else:
                    print(f"Collecting training data... ({len(self.metrics_history)}/100)")
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\nStopping anomaly detection")

def main():
    # Ensure data directory exists
    os.makedirs('/var/lib/skyvyos', exist_ok=True)
    
    detector = AnomalyDetector()
    
    if len(sys.argv) > 1 and sys.argv[1] == '--train':
        # Train mode
        if os.path.exists(DATA_FILE):
            df = pd.read_csv(DATA_FILE)
            detector.train_model(df)
        else:
            print("No historical data found. Run in continuous mode first to collect data.")
    else:
        # Continuous monitoring mode
        detector.run_continuous(interval=60)

if __name__ == '__main__':
    main()
