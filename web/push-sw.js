self.addEventListener('push', function (event) {
  if (!event.data) return;

  let data;
  try {
    data = event.data.json();
  } catch (_) {
    return;
  }

  if (typeof data !== 'object' || data === null) return;

  const title = typeof data.title === 'string' && data.title.trim()
      ? data.title.trim()
      : 'Argity Turnos';
  const body = typeof data.body === 'string' ? data.body : '';

  event.waitUntil(
    self.registration.showNotification(title, {
      body: body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: { session_id: data.session_id ?? null, url: '/' },
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});
