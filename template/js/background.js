chrome.app.runtime.onLaunched.addListener(function() {
  chrome.app.window.create('html/window.html', {
    'bounds': {
      'width': 1024,
      'height': 768
    }
  });
});
