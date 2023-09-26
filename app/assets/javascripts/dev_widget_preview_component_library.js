// Notify parent window of height changes (due to description text wrapping)
const resizeObserver = new ResizeObserver(entries => {
  const height = entries[0].contentRect.height;
  window.parent.postMessage(
    { type: 'RESIZE', payload: { component: 'dev_widget_preview', height } },
    '*'
  );
});
resizeObserver.observe(document.body);
