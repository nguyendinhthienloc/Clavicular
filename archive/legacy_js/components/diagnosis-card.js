function listItems(items) {
  if (!Array.isArray(items) || items.length === 0) return '<li>None</li>';
  return items.map((item) => `<li>${item}</li>`).join('');
}

function renderConditions(conditions) {
  if (!Array.isArray(conditions) || conditions.length === 0) {
    return '<li>No conditions returned</li>';
  }

  return conditions
    .map((c) => {
      const name = c?.name || 'Unknown';
      const likelihood = c?.likelihood || 'Unknown';
      const explanation = c?.explanation || '';
      return `<li><strong>${name}</strong> (${likelihood}) - ${explanation}</li>`;
    })
    .join('');
}

export function renderDiagnosisCard(diagnosis) {
  const card = document.getElementById('diagnosis-card');
  if (!card) return;

  card.innerHTML = `
    <h2>Diagnosis Result</h2>
    <p><strong>Severity:</strong> ${diagnosis?.severity || 'Unknown'}</p>
    <p><strong>Action:</strong> ${diagnosis?.action || 'No action provided'}</p>

    <h3>Likely Conditions</h3>
    <ul>${renderConditions(diagnosis?.conditions)}</ul>

    <h3>Home Tips</h3>
    <ul>${listItems(diagnosis?.home_tips)}</ul>

    <h3>Warning Signs</h3>
    <ul>${listItems(diagnosis?.warning_signs)}</ul>

    <p><em>${diagnosis?.disclaimer || ''}</em></p>
  `;

  card.style.display = 'block';
}
