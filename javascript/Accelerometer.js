// Global data structure read by Godot
  window.accelerometerData = { x: 0, y: 0, z: 0 };
  window.accelStatus = 'uninitialized';

  // Initialize accelerometer permission & event binding
  window.initAccelerometer = async function() {
    if (window.accelStatus.startsWith('active')) {
      return; // Already initialized
    }

    console.log('[Sensors] Requesting accelerometer access...');

    // 1. iOS Safari 13+ (Requires explicit permission call in user gesture)
    if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
      try {
        const state = await DeviceMotionEvent.requestPermission();
        if (state === 'granted') {
          window.bindDeviceMotion();
          window.accelStatus = 'active (DeviceMotion - iOS)';
          console.log('[Sensors] iOS DeviceMotion permission granted.');
        } else {
          window.accelStatus = 'denied';
          console.warn('[Sensors] DeviceMotion permission denied by user.');
        }
      } catch (err) {
        window.accelStatus = 'error: ' + err.message;
        console.error('[Sensors] Permission error:', err);
      }
      return;
    }

    // 2. Generic Sensor API (Modern Chromium / Android)
    if ('Accelerometer' in window) {
      try {
        if (navigator.permissions && navigator.permissions.query) {
          const result = await navigator.permissions.query({ name: 'accelerometer' });
          if (result.state === 'denied') {
            console.warn('[Sensors] Sensor permission denied, using devicemotion fallback.');
            window.bindDeviceMotion();
            return;
          }
        }

        const acl = new Accelerometer({ frequency: 60 });
        acl.addEventListener('reading', () => {
          window.accelerometerData.x = acl.x || 0;
          window.accelerometerData.y = acl.y || 0;
          window.accelerometerData.z = acl.z || 0;
          window.accelStatus = 'active (Generic Sensor)';
        });
        acl.addEventListener('error', (event) => {
          console.warn('[Sensors] Generic Sensor error, using devicemotion fallback:', event.error.name);
          window.bindDeviceMotion();
        });
        acl.start();
        console.log('[Sensors] Generic Sensor API active.');
        return;
      } catch (err) {
        console.warn('[Sensors] Generic Sensor init failed, using devicemotion fallback:', err.message);
      }
    }

    // 3. Fallback for standard browsers & Android Chrome devicemotion
    window.bindDeviceMotion();
  };

  window.bindDeviceMotion = function() {
    window.addEventListener('devicemotion', (event) => {
      const accel = event.acceleration || event.accelerationIncludingGravity;
      if (accel) {
        window.accelerometerData.x = accel.x || 0;
        window.accelerometerData.y = accel.y || 0;
        window.accelerometerData.z = accel.z || 0;
        window.accelStatus = 'active (devicemotion)';
      }
    }, true);
  };

  // Attempt auto-start on page load for browsers that do not require explicit gestures (e.g. Android Chrome)
  window.addEventListener('DOMContentLoaded', () => {
    window.initAccelerometer();
  });