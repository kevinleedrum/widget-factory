window.WidgetFactory = window.WidgetFactory || {};

/** Set up the modal */
window.WidgetFactory.setUpModal = function (component) {
  openModalWhenReady(component);
  addLogoClickHandler(component);
  addCloseHandlers();
};

/** Open the modal and toggle parent loading spinner */
function openModalWhenReady(component) {
  const modal = document.querySelector('mx-modal');
  modal.isOpen = true;
  window.parent.postMessage(
    {
      type: 'SET_LOADING',
      payload: { component, isLoading: false },
    },
    '*'
  );
}

/** Log an event when the logo is clicked */
function addLogoClickHandler(component) {
  const logo = document.querySelector('a img#logo');
  if (logo) {
    logo.addEventListener('click', () => {
      window.WidgetFactory.logEvent('widget_click_partner_logo');
      logEvent('widget_click_partner_logo', null, component);
    });
  }
}

/** Add close handlers to the modal */
function addCloseHandlers() {
  const modal = document.querySelector('mx-modal');
  modal.addEventListener('mxClose', sendCloseMessage);

  const closeButton = document.querySelector('.close-button');
  closeButton.addEventListener('click', sendCloseMessage);

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') sendCloseMessage();
  });
}

/** Send close message to host application */
function sendCloseMessage() {
  window.parent.postMessage({ type: 'CLOSE_EXPANDED', payload: {} }, '*');
}

/** Log an event directly to the API */
function logEvent(eventType, eventData, component) {
  _fetch(`/api/events/?session_id=${window.WidgetFactory.SESSION_ID}`, {
    method: 'POST',
    body: JSON.stringify({
      event_type: eventType,
      event_data: eventData,
      component,
    }),
  });
}

async function _fetch(url, options) {
  options = { ...options, headers: { 'Content-Type': 'application/json' } };
  const response = await fetch(url, options);
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
}
