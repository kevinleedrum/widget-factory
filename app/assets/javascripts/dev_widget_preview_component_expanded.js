/** Update the expanded preview's logo */
/** The InlineWidgetComponent already has this behavior built-in. */
window.addEventListener('message', e => {
  if (e.data.type === 'UPDATE_PREVIEW') {
    const { logo } = e.data.payload;
    const logoEl = document.querySelector('#logo');
    if (logo) {
      logoEl.src = logo;
      logoEl.classList.remove('hidden');
    } else if (logo !== undefined) {
      logoEl.classList.add('hidden');
    }
  }
});
