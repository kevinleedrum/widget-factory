let activeRequests = [];
let isWaitingToClose = false;
const root = document.querySelector('.widget_panel');
const sendCloseMessage = async () => {
  if (isWaitingToClose) return;
  isWaitingToClose = true;
  await Promise.all(activeRequests);
  window.parent.postMessage({ type: 'CLOSE_EXPANDED', payload: {} }, '*');
};
const modal = root.querySelector('mx-modal');
modal.isOpen = true;
window.parent.postMessage(
  {
    type: 'SET_LOADING',
    payload: { component: 'widget_panel', isLoading: false },
  },
  '*'
);
modal.addEventListener('mxClose', sendCloseMessage);
/* The close-on-escape behavior provided by mx-modal does not work in an iframe. */
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') sendCloseMessage();
});
document.addEventListener('DOMContentLoaded', () => {
  logEvent('widget_open_library', { timeMs: performance.now() });
});

const addButtons = root.querySelectorAll('.add-button');
addButtons.forEach(button => {
  button.addEventListener('click', async e => {
    const widgetId = e.target.closest('[data-widget-id]').dataset.widgetId;
    const component = e.target.closest('[data-widget-component]').dataset
      .widgetComponent;
    // Show "Adding widget" button
    const addButton = e.target.closest('mx-button');
    const removeButtonWrapper = addButton.parentElement.querySelector(
      '.remove-button-wrapper'
    );
    addButton.icon = 'icon icon-arrows-clockwise';
    addButton.querySelector('.button-text').innerText = 'Adding widget';
    addButton.disabled = true;
    try {
      await restoreUserWidget(widgetId, component);
      // Replace add button with remove button
      addButton.classList.add('hidden');
      removeButtonWrapper.classList.remove('hidden');
    } catch (err) {
      console.error(err);
    } finally {
      addButton.icon = 'icon icon-plus-circle';
      addButton.querySelector('.button-text').innerText = 'Add widget';
      addButton.disabled = false;
    }
  });
});
const removeButtons = root.querySelectorAll('.remove-button');
removeButtons.forEach(button => {
  button.addEventListener('click', async e => {
    const widgetId = e.target.closest('[data-widget-id]').dataset.widgetId;
    const component = e.target.closest('[data-widget-component]').dataset
      .widgetComponent;
    const removeButton = e.target.closest('mx-button');
    const removeButtonWrapper = e.target.closest('.remove-button-wrapper');
    const addedButton = removeButtonWrapper.querySelector('.added-button');
    const addButton =
      removeButtonWrapper.parentElement.querySelector('.add-button');
    removeButton.icon = 'icon icon-arrows-clockwise';
    removeButton.classList.replace('opacity-0', 'opacity-100');
    addedButton.classList.add('opacity-0');
    removeButton.querySelector('.button-text').innerText = 'Removing widget';
    removeButton.disabled = true;
    try {
      await destroyUserWidget(widgetId, component);
      // Replace remove button with add button
      addButton.classList.remove('hidden');
      removeButtonWrapper.classList.add('hidden');
    } catch (err) {
      console.error(err);
    } finally {
      removeButton.classList.replace('opacity-100', 'opacity-0');
      addedButton.classList.remove('opacity-0');
      removeButton.icon = 'icon icon-minus-circle';
      removeButton.querySelector('.button-text').innerText =
        'Remove from Dashboard';
      removeButton.disabled = false;
    }
  });
});

function logEvent(eventType, eventData, component = 'widget_panel') {
  _fetch(
    `/api/events/?session_id=${window.WidgetFactory.SESSION_ID}`,
    {
      method: 'POST',
      body: JSON.stringify({
        event_type: eventType,
        event_data: eventData,
        component,
      }),
    },
    true
  );
}

function restoreUserWidget(widgetId, component) {
  logEvent('widget_add_via_library', null, component);
  return _fetch(
    `/api/user_widgets/${widgetId}/restore?session_id=${window.WidgetFactory.SESSION_ID}`,
    {
      method: 'POST',
    }
  );
}
function destroyUserWidget(widgetId, component) {
  logEvent('widget_remove_via_library', null, component);
  return _fetch(
    `/api/user_widgets/${widgetId}?session_id=${window.WidgetFactory.SESSION_ID}`,
    {
      method: 'DELETE',
    }
  );
}
async function _fetch(url, options, silent = false) {
  options = { ...options, headers: { 'Content-Type': 'application/json' } };
  const promise = fetch(url, options);
  activeRequests.push(promise);
  const response = await promise;
  activeRequests = activeRequests.filter(p => p !== promise);
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
    return;
  }
  if (!silent) {
    window.parent.postMessage(
      {
        type: 'SET_LOADING',
        payload: { component: 'widget_panel', isLoading: true },
      },
      '*'
    );
    window.parent.postMessage(
      { type: 'REFRESH', payload: { component: 'widget_panel' } },
      '*'
    );
  }
}
