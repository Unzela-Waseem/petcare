importScripts('https://www.gstatic.com/firebasejs/12.17.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.17.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBuZSAN2U56u9yITI4Ldw4hPHAeAzrLzWc',
  authDomain: 'pawfectcare-unzela-2026.firebaseapp.com',
  projectId: 'pawfectcare-unzela-2026',
  storageBucket: 'pawfectcare-unzela-2026.firebasestorage.app',
  messagingSenderId: '292981245129',
  appId: '1:292981245129:web:5ccef1aafe8f53d927f918',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage(() => {
  // Notification payloads are displayed by the browser automatically.
});
