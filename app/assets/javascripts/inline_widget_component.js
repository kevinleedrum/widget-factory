window.WidgetFactory = window.WidgetFactory || {};

/** Handle common message events */
window.WidgetFactory.addMessageHandler = function (component) {
  window.addEventListener('message', e => {
    if (e.data.type === 'UPDATE_PREVIEW')
      updatePreview(component, e.data.payload);
    if (e.data.type === 'SET_LOADING' && e.data.payload.component === component)
      window.WidgetFactory.setLoading(component, e.data.payload.isLoading);
  });
};

/** Set up the widget context menu */
window.WidgetFactory.initMenu = function (component) {
  const root = document.querySelector(`.${component}`);
  const menu = root.querySelector('mx-menu');
  const menuButton = root.querySelector('.menu-button');
  if (menu && menuButton) {
    menu.anchorEl = menuButton;
    menuButton.addEventListener('click', () => {
      window.WidgetFactory.logEvent('widget_open_menu', null, component);
    });
  }
  const menuItems = root.querySelectorAll('mx-menu-item');
  if (menuItems.length) {
    menuItems[0].addEventListener('click', () => {
      window.self.postMessage({ type: 'REMOVE', payload: { component } }, '*');
    });
  }
};

/** Log an event when the logo is clicked */
window.WidgetFactory.addLogoClickHandler = function (component) {
  const root = document.querySelector(`.${component}`);
  const logo = root.querySelector('a img#logo');
  if (logo) {
    logo.addEventListener('click', () => {
      window.WidgetFactory.logEvent(
        'widget_click_partner_logo',
        null,
        component
      );
    });
  }
};

/** When the user clicks the expand button, expand the widget and log an event */
window.WidgetFactory.addExpandClickHandler = function (component) {
  const expandButton = document.querySelector(`.${component} .expand-button`);
  if (expandButton)
    expandButton.addEventListener('click', () => {
      window.WidgetFactory.expand(component);
      window.WidgetFactory.logEvent('widget_expand', null, component);
    });
};

/** Expand the widget */
window.WidgetFactory.expand = function (component) {
  const root = document.querySelector(`.${component}`);
  let url = root.dataset.expandedUrl;
  if (!url) return;
  if (!url.startsWith('http')) url = window.location.origin + url;
  window.WidgetFactory.setLoading(component, true);
  window.parent.postMessage({ type: 'EXPAND', payload: { url } }, '*');
};

/** Set the loading state of the widget */
window.WidgetFactory.setLoading = function (component, isLoading) {
  const loading = document.querySelector(`.${component} .loading`);
  if (!loading) return;
  if (isLoading) {
    loading.classList.replace('hidden', 'flex');
  } else {
    loading.classList.replace('flex', 'hidden');
  }
};

/** Log an event */
window.WidgetFactory.logEvent = function (eventType, eventData, component) {
  window.self.postMessage(
    {
      type: 'LOG_EVENT',
      payload: {
        eventType,
        eventData,
        component,
      },
    },
    '*'
  );
};

/** Update the widget's logo and heading (from an UPDATE_PREVIEW message from the admin form) */
function updatePreview(component, { heading, logo }) {
  const root = document.querySelector(`.${component}`);
  if (heading) root.querySelector('#heading').innerText = heading;
  const logoEl = root.querySelector('#logo');
  if (logo) {
    logoEl.src = logo;
    logoEl.classList.remove('hidden');
  } else if (logo !== undefined) {
    logoEl.classList.add('hidden');
  }
}
