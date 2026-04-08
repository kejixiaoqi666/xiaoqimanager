async function fetchJson(path) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Request failed: ${response.status}`);
  }
  return response.json();
}

function renderSummary(summary) {
  const el = document.getElementById('summary');
  el.innerHTML = `
    <h2>服务总览</h2>
    <p>总数：<strong>${summary.total}</strong></p>
    <p>在线：<strong>${summary.online}</strong>，离线：<strong>${summary.offline}</strong></p>
  `;
}

function renderServices(services) {
  const container = document.getElementById('service-list');
  const tpl = document.getElementById('service-card-template');
  container.innerHTML = '';

  for (const service of services) {
    const node = tpl.content.firstElementChild.cloneNode(true);
    for (const field of ['name', 'path', 'config', 'port', 'healthEndpoint']) {
      node.querySelector(`[data-field="${field}"]`).textContent = service[field];
    }

    const statusEl = node.querySelector('[data-field="status"]');
    statusEl.textContent = service.status;
    statusEl.classList.add(service.status);

    const envPreview = Object.entries(service.envPreview || {})
      .map(([k, v]) => `${k}=${v}`)
      .join('\n') || '(empty)';
    node.querySelector('[data-field="envPreview"]').textContent = envPreview;

    container.appendChild(node);
  }
}

async function bootstrap() {
  try {
    const [summary, servicePayload] = await Promise.all([
      fetchJson('/api/summary'),
      fetchJson('/api/services')
    ]);

    renderSummary(summary);
    renderServices(servicePayload.services || []);
  } catch (err) {
    const root = document.querySelector('.container');
    const p = document.createElement('p');
    p.textContent = `加载失败：${err.message}`;
    root.appendChild(p);
  }
}

bootstrap();
