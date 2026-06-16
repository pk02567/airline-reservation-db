/* ============================================================
   AIRLINE RESERVATION SYSTEM — DASHBOARD SCRIPT
   DBMS Mini Project | DSATM | B.Tech CSE-ICB
   ============================================================ */

'use strict';

// ============================================================
// DATA (mirrors the database state after all INSERTs)
// ============================================================

const BOOKINGS = [
  { pnr:'PNR001', passenger:'Priya Sharma',   route:'BLR → DEL', flight:'AI-204', dep:'05 Jun 06:00', seat:'4A',  cls:'ECONOMY',  amount:4200,  method:'UPI',        status:'CANCELLED' },
  { pnr:'PNR002', passenger:'Rahul Mehta',    route:'BLR → DEL', flight:'AI-204', dep:'05 Jun 06:00', seat:'4B',  cls:'ECONOMY',  amount:4200,  method:'CARD',       status:'CONFIRMED' },
  { pnr:'PNR003', passenger:'Ananya Iyer',    route:'BLR → DEL', flight:'AI-204', dep:'05 Jun 06:00', seat:'1A',  cls:'BUSINESS', amount:12500, method:'NETBANKING', status:'CONFIRMED' },
  { pnr:'PNR004', passenger:'Karan Verma',    route:'BLR → BOM', flight:'6E-301', dep:'05 Jun 09:30', seat:'1A',  cls:'BUSINESS', amount:9800,  method:'CARD',       status:'CONFIRMED' },
  { pnr:'PNR005', passenger:'Sneha Nair',     route:'BLR → DEL', flight:'AI-204', dep:'05 Jun 06:00', seat:'10A', cls:'ECONOMY',  amount:3800,  method:'WALLET',     status:'CONFIRMED' },
  { pnr:'PNR006', passenger:'Arjun Patel',    route:'BLR → BOM', flight:'6E-301', dep:'05 Jun 09:30', seat:'3A',  cls:'ECONOMY',  amount:2900,  method:'UPI',        status:'CONFIRMED' },
  { pnr:'PNR007', passenger:'Divya Reddy',    route:'BLR → DEL', flight:'AI-204', dep:'05 Jun 06:00', seat:'4C',  cls:'ECONOMY',  amount:4200,  method:'CARD',       status:'CONFIRMED' },
  { pnr:'PNR008', passenger:'Vikram Singh',   route:'BLR → DEL', flight:'AI-204', dep:'05 Jun 06:00', seat:'1B',  cls:'BUSINESS', amount:12500, method:'NETBANKING', status:'CONFIRMED' },
];

// Seat map data for AI-204 (flight_id = 1)
// seat_id 4 = seat 4A (Priya's seat, initially BOOKED by trigger)
const SEATMAP = [
  // Business class
  { id:1,  num:'1A',  cls:'BUSINESS', price:12500, booked:true,  passenger:'Ananya Iyer'  },
  { id:2,  num:'1B',  cls:'BUSINESS', price:12500, booked:true,  passenger:'Vikram Singh' },
  { id:3,  num:'2A',  cls:'BUSINESS', price:11800, booked:false, passenger:null           },
  // Economy class
  { id:4,  num:'4A',  cls:'ECONOMY',  price:4200,  booked:true,  passenger:'Priya Sharma' },  // cancellable
  { id:5,  num:'4B',  cls:'ECONOMY',  price:4200,  booked:true,  passenger:'Rahul Mehta'  },
  { id:6,  num:'4C',  cls:'ECONOMY',  price:4200,  booked:true,  passenger:'Divya Reddy'  },
  { id:7,  num:'10A', cls:'ECONOMY',  price:3800,  booked:true,  passenger:'Sneha Nair'   },
  { id:8,  num:'10B', cls:'ECONOMY',  price:3800,  booked:false, passenger:null           },
  { id:9,  num:'15A', cls:'ECONOMY',  price:3500,  booked:false, passenger:null           },
  { id:10, num:'15B', cls:'ECONOMY',  price:3500,  booked:false, passenger:null           },
];

// ============================================================
// NAV / ROUTING
// ============================================================

const PAGE_TITLES = {
  overview:     'System Overview',
  flights:      'All Flights',
  seatmap:      'Seat Map — AI-204',
  bookings:     'Booking Details',
  revenue:      'Revenue Analytics',
  occupancy:    'Flight Occupancy',
  cancellation: 'Cancellation Demo',
  schema:       'Database Schema',
  queries:      'SQL Query Explorer',
};

let chartsInitialized = false;

document.querySelectorAll('.nav-item').forEach(item => {
  item.addEventListener('click', () => {
    const page = item.dataset.page;
    navigateTo(page);
  });
});

function navigateTo(page) {
  // Close mobile sidebar if open
  document.querySelector('.sidebar').classList.remove('open');

  // Update nav
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById('nav-' + page).classList.add('active');

  // Update pages
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.getElementById('page-' + page).classList.add('active');

  // Update topbar
  document.getElementById('topbar-title').textContent = PAGE_TITLES[page];

  // Lazy init charts
  if ((page === 'revenue' || page === 'occupancy') && !chartsInitialized) {
    initCharts();
    chartsInitialized = true;
  }

  // Animate occupancy bars on page load
  if (page === 'occupancy') {
    setTimeout(() => {
      document.querySelectorAll('.occ-bar-fill').forEach(bar => {
        const target = bar.style.width;
        bar.style.width = '0%';
        setTimeout(() => { bar.style.width = target; }, 50);
      });
    }, 100);
  }

  // Auto-activate Step A when first entering cancellation page
  if (page === 'cancellation' && cancelStep === 0) {
    const step0 = document.getElementById('step-0');
    if (step0 && !step0.classList.contains('active') && !step0.classList.contains('done')) {
      step0.classList.add('active');
    }
  }
}

// ============================================================
// SEAT MAP RENDERER
// ============================================================

function renderSeatMap(cancelledSeatId = null) {
  const container = document.getElementById('seat-map-container');
  if (!container) return;

  // Separate by class
  const biz = SEATMAP.filter(s => s.cls === 'BUSINESS');
  const eco = SEATMAP.filter(s => s.cls === 'ECONOMY');

  let html = '';

  // Business section
  html += `<div class="seat-class-label">🟣 Business Class</div>`;
  // Pair them in rows of 2
  for (let i = 0; i < biz.length; i += 2) {
    html += `<div class="seat-row">`;
    for (let j = i; j < Math.min(i+2, biz.length); j++) {
      html += buildSeat(biz[j], cancelledSeatId);
    }
    html += `</div>`;
  }

  // Economy section
  html += `<div class="seat-class-label">🟢 Economy Class</div>`;
  // 3 seats per row (A B C)
  for (let i = 0; i < eco.length; i += 3) {
    html += `<div class="seat-row">`;
    for (let j = i; j < Math.min(i+3, eco.length); j++) {
      html += buildSeat(eco[j], cancelledSeatId);
      if (j === i+1 && eco.length > i+2) html += `<div class="aisle"></div>`;
    }
    html += `</div>`;
  }

  container.innerHTML = html;
}

function buildSeat(seat, cancelledSeatId) {
  let cls, icon, statusText, tooltipExtra;

  const isCancelled = (seat.id === cancelledSeatId);

  if (isCancelled) {
    cls        = 'seat released';
    icon       = '✓';
    statusText = 'AVAILABLE';
    tooltipExtra = `<br>Released by trigger!`;
  } else if (seat.booked) {
    cls        = seat.cls === 'BUSINESS' ? 'seat biz-booked' : 'seat booked';
    icon       = '✕';
    statusText = 'BOOKED';
    tooltipExtra = seat.passenger ? `<br>Passenger: ${seat.passenger}` : '';
  } else if (seat.cls === 'BUSINESS') {
    cls        = 'seat biz-available';
    icon       = '💼';
    statusText = 'AVAILABLE';
    tooltipExtra = '';
  } else {
    cls        = 'seat eco-available';
    icon       = '💺';
    statusText = 'AVAILABLE';
    tooltipExtra = '';
  }

  return `
    <div class="${cls}" title="${seat.num}">
      <span class="seat-icon">${icon}</span>
      <span class="seat-num">${seat.num}</span>
      <div class="seat-tooltip">
        <strong>${seat.num}</strong> · ${seat.cls}<br>
        ₹${seat.price.toLocaleString('en-IN')}<br>
        ${statusText}${tooltipExtra}
      </div>
    </div>`;
}

// ============================================================
// BOOKINGS TABLE
// ============================================================

function renderBookingsTable() {
  const tbody = document.getElementById('bookings-tbody');
  if (!tbody) return;

  const classBadge = cls => cls === 'BUSINESS'
    ? `<span class="badge badge-purple">BUSINESS</span>`
    : `<span class="badge badge-cyan">ECONOMY</span>`;

  const statusBadge = s => {
    const map = {
      CONFIRMED: 'badge-green',
      CANCELLED:  'badge-red',
      WAITLISTED: 'badge-yellow',
    };
    return `<span class="badge ${map[s] || 'badge-blue'}">${s}</span>`;
  };

  const methodIcon = m => ({ UPI:'📲', CARD:'💳', NETBANKING:'🏦', WALLET:'👛' })[m] || '';

  tbody.innerHTML = BOOKINGS.map(b => `
    <tr>
      <td><strong>${b.pnr}</strong></td>
      <td>${b.passenger}</td>
      <td>${b.route}</td>
      <td><strong>${b.flight}</strong></td>
      <td>${b.dep}</td>
      <td><strong>${b.seat}</strong></td>
      <td>${classBadge(b.cls)}</td>
      <td><strong style="color:var(--accent-green)">₹${b.amount.toLocaleString('en-IN')}</strong></td>
      <td>${methodIcon(b.method)} ${b.method}</td>
      <td id="booking-status-${b.pnr}">${statusBadge(b.status)}</td>
    </tr>`).join('');
}

// ============================================================
// CHARTS
// ============================================================

const CHART_DEFAULTS = {
  color: '#8ba3c0',
  grid:  'rgba(255,255,255,0.05)',
  font:  { family: 'Inter', size: 12 },
};

function chartDefaults() {
  Chart.defaults.color      = CHART_DEFAULTS.color;
  Chart.defaults.font.family= CHART_DEFAULTS.font.family;
  Chart.defaults.font.size  = CHART_DEFAULTS.font.size;
}

function initCharts() {
  chartDefaults();

  // Revenue per flight (Bar)
  new Chart(document.getElementById('revenueChart'), {
    type: 'bar',
    data: {
      labels: ['AI-204 (BLR→DEL)', '6E-301 (BLR→BOM)'],
      datasets: [{
        label: 'Revenue (₹)',
        data:  [37200, 12700],
        backgroundColor: [
          'rgba(59,158,255,0.7)',
          'rgba(168,85,247,0.7)',
        ],
        borderColor: [
          'rgba(59,158,255,1)',
          'rgba(168,85,247,1)',
        ],
        borderWidth: 2,
        borderRadius: 8,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: ctx => ` ₹${ctx.parsed.y.toLocaleString('en-IN')}`,
          }
        }
      },
      scales: {
        x: { grid: { color: CHART_DEFAULTS.grid }, ticks: { color: CHART_DEFAULTS.color } },
        y: {
          grid: { color: CHART_DEFAULTS.grid },
          ticks: {
            color: CHART_DEFAULTS.color,
            callback: v => '₹' + (v/1000) + 'k',
          }
        }
      }
    }
  });

  // Business vs Economy (Doughnut)
  new Chart(document.getElementById('classChart'), {
    type: 'doughnut',
    data: {
      labels: ['Business (₹34,800)', 'Economy (₹15,100)'],
      datasets: [{
        data: [34800, 15100],
        backgroundColor: [
          'rgba(168,85,247,0.75)',
          'rgba(34,211,160,0.75)',
        ],
        borderColor: [
          'rgba(168,85,247,1)',
          'rgba(34,211,160,1)',
        ],
        borderWidth: 2,
        hoverOffset: 10,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'bottom',
          labels: { padding: 20, usePointStyle: true, pointStyleWidth: 10 }
        },
        tooltip: {
          callbacks: {
            label: ctx => ` ₹${ctx.parsed.toLocaleString('en-IN')} (${ctx.label.split(' ')[0]})`,
          }
        }
      },
      cutout: '60%',
    }
  });

  // Occupancy (Horizontal Bar)
  new Chart(document.getElementById('occupancyChart'), {
    type: 'bar',
    data: {
      labels: ['AI-204', '6E-301', 'SG-415', 'AI-890', '6E-112'],
      datasets: [{
        label: 'Occupancy %',
        data: [3.1, 1.3, 0, 0, 0],
        backgroundColor: [
          'rgba(59,158,255,0.75)',
          'rgba(168,85,247,0.75)',
          'rgba(34,211,160,0.5)',
          'rgba(251,191,36,0.5)',
          'rgba(34,211,160,0.5)',
        ],
        borderColor: [
          'rgba(59,158,255,1)',
          'rgba(168,85,247,1)',
          'rgba(34,211,160,0.7)',
          'rgba(251,191,36,0.7)',
          'rgba(34,211,160,0.7)',
        ],
        borderWidth: 2,
        borderRadius: 8,
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: { label: ctx => ` ${ctx.parsed.x}% occupied` }
        }
      },
      scales: {
        x: {
          grid: { color: CHART_DEFAULTS.grid },
          ticks: { color: CHART_DEFAULTS.color, callback: v => v + '%' },
          max: 10,
        },
        y: { grid: { color: CHART_DEFAULTS.grid }, ticks: { color: CHART_DEFAULTS.color } }
      }
    }
  });
}

// ============================================================
// QUERY ACCORDION
// ============================================================

function toggleQuery(n) {
  const card = document.getElementById('qcard-' + n);
  if (!card) return;
  card.classList.toggle('open');
}

function copySQL(n) {
  const pre = document.querySelector('#qbody-' + n + ' .sql-block');
  if (!pre) return;
  const btn = document.getElementById('copy-btn-' + n);
  const text = pre.textContent.trim();
  navigator.clipboard.writeText(text).then(() => {
    if (btn) btn.textContent = '✓ Copied!';
    setTimeout(() => { if (btn) btn.textContent = '📋 Copy'; }, 2000);
  }).catch(() => {
    // Fallback for older browsers / file:// protocol
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
    if (btn) btn.textContent = '✓ Copied!';
    setTimeout(() => { if (btn) btn.textContent = '📋 Copy'; }, 2000);
  });
}

// ============================================================
// CANCELLATION DEMO
// ============================================================

let cancelStep = 0;
const TOTAL_STEPS = 5;

function nextCancelStep() {
  if (cancelStep >= TOTAL_STEPS) return;

  const stepEl = document.getElementById('step-' + cancelStep);
  stepEl.classList.add('done');
  stepEl.querySelector('.step-marker').textContent = '✓';

  // Special effects per step
  if (cancelStep === 1) {
    // Step B: booking status → CANCELLED
    const statusEl = document.getElementById('cancel-booking-status');
    if (statusEl) statusEl.innerHTML = `<span class="badge badge-red">CANCELLED</span>`;
    // Also update bookings table if it exists
    const tableStatus = document.getElementById('booking-status-PNR001');
    if (tableStatus) tableStatus.innerHTML = `<span class="badge badge-red">CANCELLED</span>`;
  }

  if (cancelStep === 2) {
    // Step C: trigger fires → seat 4A released
    const seatViz = document.getElementById('cancel-seat-visual');
    if (seatViz) {
      seatViz.className = 'seat released';
      seatViz.style.width  = '100px';
      seatViz.style.height = '100px';
      seatViz.style.fontSize = '16px';
      seatViz.style.borderRadius = '16px';
      seatViz.style.fontWeight = '800';
      seatViz.innerHTML = `
        <span class="seat-icon">🔓</span>
        <span class="seat-num" style="font-size:14px;">4A</span>
        <span style="font-size:10px;margin-top:4px;color:var(--accent-green)">AVAILABLE</span>`;
    }
    // Re-render seat map with 4A released
    renderSeatMap(4);
  }

  cancelStep++;

  // Mark next step as active
  if (cancelStep < TOTAL_STEPS) {
    const next = document.getElementById('step-' + cancelStep);
    if (next) next.classList.add('active');
  }

  // Disable button when done
  const btn = document.getElementById('btn-next-step');
  if (cancelStep >= TOTAL_STEPS) {
    btn.textContent = '✅ Demo Complete';
    btn.disabled = true;
  }
}

function resetCancelDemo() {
  cancelStep = 0;

  // Reset all steps
  for (let i = 0; i < TOTAL_STEPS; i++) {
    const step = document.getElementById('step-' + i);
    step.classList.remove('done', 'active');
    step.querySelector('.step-marker').textContent = String.fromCharCode(65 + i); // A, B, C, D, E
  }

  // Reset booking status badge
  const statusEl = document.getElementById('cancel-booking-status');
  if (statusEl) statusEl.innerHTML = `<span class="badge badge-green">CONFIRMED</span>`;

  const tableStatus = document.getElementById('booking-status-PNR001');
  if (tableStatus) tableStatus.innerHTML = `<span class="badge badge-green">CONFIRMED</span>`;

  // Reset seat visual
  const seatViz = document.getElementById('cancel-seat-visual');
  if (seatViz) {
    seatViz.className = 'seat booked';
    seatViz.style.width  = '100px';
    seatViz.style.height = '100px';
    seatViz.style.fontSize = '16px';
    seatViz.style.borderRadius = '16px';
    seatViz.style.fontWeight = '800';
    seatViz.innerHTML = `
      <span class="seat-icon">🔒</span>
      <span class="seat-num" style="font-size:14px;">4A</span>
      <span style="font-size:10px;margin-top:4px;color:var(--accent-red)">BOOKED</span>`;
  }

  // Reset seat map
  renderSeatMap(null);

  // Reset button
  const btn = document.getElementById('btn-next-step');
  btn.textContent = '▶ Execute Next Step';
  btn.disabled = false;
}

// ============================================================
// INIT
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
  renderSeatMap(null);
  renderBookingsTable();

  // Mobile sidebar hamburger toggle
  const menuToggle = document.getElementById('menu-toggle');
  if (menuToggle) {
    menuToggle.addEventListener('click', () => {
      document.querySelector('.sidebar').classList.toggle('open');
    });
  }
});
