#!/usr/bin/env python3
"""
Contoh server Socket.io untuk Raspberry Pi
Untuk menerima perintah dari aplikasi Robot Edukasi Flutter

Dependencies:
pip install python-socketio eventlet RPi.GPIO

Jalankan dengan:
python3 raspberry_pi_server_example.py
"""

import socketio
import eventlet
import json
import time
import threading
from datetime import datetime

# Uncomment jika menggunakan GPIO Raspberry Pi
# import RPi.GPIO as GPIO

# Konfigurasi Socket.io server
sio = socketio.Server(cors_allowed_origins="*")
app = socketio.WSGIApp(sio)

# Status robot
robot_status = {
    'connected': False,
    'current_command': 'stop',
    'last_update': None
}

# GPIO pins untuk motor (contoh)
# GPIO.setmode(GPIO.BCM)
# MOTOR_LEFT_FORWARD = 18
# MOTOR_LEFT_BACKWARD = 19
# MOTOR_RIGHT_FORWARD = 20
# MOTOR_RIGHT_BACKWARD = 21

def setup_gpio():
    """Setup GPIO pins untuk motor"""
    # GPIO.setup(MOTOR_LEFT_FORWARD, GPIO.OUT)
    # GPIO.setup(MOTOR_LEFT_BACKWARD, GPIO.OUT)
    # GPIO.setup(MOTOR_RIGHT_FORWARD, GPIO.OUT)
    # GPIO.setup(MOTOR_RIGHT_BACKWARD, GPIO.OUT)
    print("🔧 GPIO setup completed")

def execute_robot_command(command):
    """Eksekusi perintah robot"""
    print(f"🤖 Executing command: {command}")
    
    if command == 'forward':
        # GPIO.output(MOTOR_LEFT_FORWARD, GPIO.HIGH)
        # GPIO.output(MOTOR_RIGHT_FORWARD, GPIO.HIGH)
        # GPIO.output(MOTOR_LEFT_BACKWARD, GPIO.LOW)
        # GPIO.output(MOTOR_RIGHT_BACKWARD, GPIO.LOW)
        print("   ⬆️ Moving forward")
        
    elif command == 'backward':
        # GPIO.output(MOTOR_LEFT_FORWARD, GPIO.LOW)
        # GPIO.output(MOTOR_RIGHT_FORWARD, GPIO.LOW)
        # GPIO.output(MOTOR_LEFT_BACKWARD, GPIO.HIGH)
        # GPIO.output(MOTOR_RIGHT_BACKWARD, GPIO.HIGH)
        print("   ⬇️ Moving backward")
        
    elif command == 'left':
        # GPIO.output(MOTOR_LEFT_FORWARD, GPIO.LOW)
        # GPIO.output(MOTOR_RIGHT_FORWARD, GPIO.HIGH)
        # GPIO.output(MOTOR_LEFT_BACKWARD, GPIO.HIGH)
        # GPIO.output(MOTOR_RIGHT_BACKWARD, GPIO.LOW)
        print("   ⬅️ Turning left")
        
    elif command == 'right':
        # GPIO.output(MOTOR_LEFT_FORWARD, GPIO.HIGH)
        # GPIO.output(MOTOR_RIGHT_FORWARD, GPIO.LOW)
        # GPIO.output(MOTOR_LEFT_BACKWARD, GPIO.LOW)
        # GPIO.output(MOTOR_RIGHT_BACKWARD, GPIO.HIGH)
        print("   ➡️ Turning right")
        
    elif command == 'stop':
        # GPIO.output(MOTOR_LEFT_FORWARD, GPIO.LOW)
        # GPIO.output(MOTOR_RIGHT_FORWARD, GPIO.LOW)
        # GPIO.output(MOTOR_LEFT_BACKWARD, GPIO.LOW)
        # GPIO.output(MOTOR_RIGHT_BACKWARD, GPIO.LOW)
        print("   ⏹️ Stopping")
    
    robot_status['current_command'] = command
    robot_status['last_update'] = datetime.now().isoformat()

def execute_command_sequence(commands):
    """Eksekusi urutan perintah"""
    print(f"📋 Executing command sequence: {len(commands)} commands")
    
    for i, cmd in enumerate(commands):
        command_type = cmd.get('type', 'stop')
        duration = cmd.get('duration', 1.0)
        
        print(f"   Step {i+1}: {command_type} for {duration}s")
        execute_robot_command(command_type)
        time.sleep(duration)
    
    # Stop robot after sequence
    execute_robot_command('stop')
    print("✅ Command sequence completed")

@sio.event
def connect(sid, environ):
    """Client terhubung"""
    print(f"🟢 Client connected: {sid}")
    robot_status['connected'] = True
    sio.emit('robot_status', robot_status, room=sid)

@sio.event
def disconnect(sid):
    """Client terputus"""
    print(f"🔴 Client disconnected: {sid}")
    robot_status['connected'] = False
    execute_robot_command('stop')  # Stop robot saat disconnect

@sio.event
def joystick_command(sid, data):
    """Menerima perintah joystick"""
    command = data.get('command', 'stop')
    timestamp = data.get('timestamp', 0)
    
    print(f"🕹️ Joystick command from {sid}: {command}")
    execute_robot_command(command)
    
    # Send acknowledgment
    sio.emit('command_ack', {
        'type': 'joystick',
        'command': command,
        'status': 'executed',
        'timestamp': timestamp
    }, room=sid)

@sio.event
def voice_command(sid, data):
    """Menerima perintah suara"""
    command = data.get('command', 'stop')
    timestamp = data.get('timestamp', 0)
    
    print(f"🎤 Voice command from {sid}: {command}")
    execute_robot_command(command)
    
    # Send acknowledgment
    sio.emit('command_ack', {
        'type': 'voice',
        'command': command,
        'status': 'executed',
        'timestamp': timestamp
    }, room=sid)

@sio.event
def run_commands(sid, data):
    """Menerima urutan perintah"""
    commands = data.get('data', [])
    timestamp = data.get('timestamp', 0)
    
    print(f"📋 Command sequence from {sid}: {len(commands)} commands")
    
    # Jalankan sequence di thread terpisah agar tidak blocking
    def run_sequence():
        execute_command_sequence(commands)
        sio.emit('sequence_completed', {
            'status': 'completed',
            'commands_count': len(commands),
            'timestamp': timestamp
        }, room=sid)
    
    thread = threading.Thread(target=run_sequence)
    thread.daemon = True
    thread.start()
    
    # Send acknowledgment
    sio.emit('command_ack', {
        'type': 'sequence',
        'commands_count': len(commands),
        'status': 'started',
        'timestamp': timestamp
    }, room=sid)

@sio.event
def get_robot_status(sid, data):
    """Mendapatkan status robot"""
    print(f"📊 Status request from {sid}")
    sio.emit('robot_status', robot_status, room=sid)

def main():
    """Main function"""
    print("🤖 Robot Edukasi Server Starting...")
    print("📡 Socket.io server will run on http://0.0.0.0:5000")
    print("🔧 Setting up GPIO...")
    
    setup_gpio()
    
    print("✅ Server ready!")
    print("📱 Waiting for Flutter app connections...")
    print("🛑 Press Ctrl+C to stop")
    
    try:
        # Jalankan server di port 5000
        eventlet.wsgi.server(eventlet.listen(('0.0.0.0', 5000)), app)
    except KeyboardInterrupt:
        print("\n🛑 Server stopping...")
        execute_robot_command('stop')  # Stop robot
        # GPIO.cleanup()  # Cleanup GPIO
        print("👋 Server stopped")

if __name__ == '__main__':
    main()
