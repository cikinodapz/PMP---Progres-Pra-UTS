importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: 'AIzaSyAT1ixWrgL3ScDwAhwqLn9eS3t_IjesVUE',
    appId: '1:240070260442:web:cc49c4f40e61ca19af17e3',
    messagingSenderId: '240070260442',
    projectId: 'flashcard-70248',
    authDomain: 'flashcard-70248.firebaseapp.com',
    storageBucket: 'flashcard-70248.firebasestorage.app',
    measurementId: 'G-M6613QJFRP',
});

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/icon-192x192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
}); 