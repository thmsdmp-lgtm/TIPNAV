/* ==========================================================
   1. CAMPUS DATABASE
   ========================================================== */
const campusPlaces = {
  "placeh1": {
    name: "Placeholder 1",
    category: "Laboratories",
    location: "PH 1 LOC",
    time: "3 Min",
    distance: "120 m",
    hours: "Mon - Fri: 7:30 AM – 6:00 PM",
    room: "Building 1, Room 101",
    inCharge: "Office 1",
    contact: "contact@campus.edu",
    desc: "Computer lab and testing area.",
    bannerImg: null,
    gallery: null,
    services: [
      "Book Borrowing & Return",
      "Research Terminals",
      "Quiet Study Cubicles",
      "Printing & Photocopying"
    ]
  },
  "placeh2": {
    name: "Placeholder 2",
    category: "Classrooms",
    location: "PH 2 LOC",
    time: "2 Min",
    distance: "80 m",
    hours: "Mon - Sat: 8:00 AM – 5:00 PM",
    room: "Building 2, Room 202",
    inCharge: "Office 2",
    contact: "contact@campus.edu",
    desc: "Lecture hall.",
    bannerImg: null,
    gallery: null,
    services: [
      "Lecture Hall Bookings",
      "Audio-Visual Equipment Setup"
    ]
  },
  "placeh3": {
    name: "Placeholder 3",
    category: "Administrative Offices",
    location: "PH 3 LOC",
    time: "5 Min",
    distance: "200 m",
    hours: "Mon - Fri: 8:00 AM – 4:00 PM",
    room: "Building 3, Room 303",
    inCharge: "Office 3",
    contact: "contact@campus.edu",
    desc: "Administrative office.",
    bannerImg: null,
    gallery: null,
    services: [
      "Document Clearance",
      "Student Records Inquiries"
    ]
  },
  "placeh4": {
    name: "Placeholder 4",
    category: "Finance & Cashier",
    location: "PH 4 LOC",
    time: "4 Min",
    distance: "150 m",
    hours: "Mon - Fri: 8:00 AM – 5:00 PM",
    room: "Building 4, Room 404",
    inCharge: "Office 4",
    contact: "contact@campus.edu",
    desc: "Finance and Cashier payment counters.",
    bannerImg: null,
    gallery: null,
    services: [
      "Tuition Payments",
      "Assessment Inquiries",
      "Official Receipts Issuance"
    ]
  }
};

/* ==========================================================
   2. SPA VIEW ROUTER
   ========================================================== */
let viewHistory = ['viewHome'];

function navigateTo(viewId) {
  const views = document.querySelectorAll('.app-view');
  views.forEach(v => v.classList.remove('active'));

  const target = document.getElementById(viewId);
  if (target) {
    target.classList.add('active');
    viewHistory.push(viewId);
    window.scrollTo(0, 0);
  }

  updateDock(viewId);
}

function goBackView() {
  if (viewHistory.length > 1) {
    viewHistory.pop(); // remove current view
    const prevView = viewHistory[viewHistory.length - 1];

    const views = document.querySelectorAll('.app-view');
    views.forEach(v => v.classList.remove('active'));

    const target = document.getElementById(prevView);
    if (target) {
      target.classList.add('active');
      window.scrollTo(0, 0);
    }

    updateDock(prevView);
  } else {
    navigateTo('viewHome');
  }
}

function updateDock(viewId) {
  const dockHome = document.getElementById('dock-home');
  const dockMap = document.getElementById('dock-map');
  const dockCat = document.getElementById('dock-category');

  if (!dockHome || !dockMap || !dockCat) return;

  dockHome.classList.remove('active');
  dockMap.classList.remove('active');
  dockCat.classList.remove('active');

  if (viewId === 'viewHome') dockHome.classList.add('active');
  else if (viewId === 'viewMap') dockMap.classList.add('active');
  else if (viewId === 'viewCategories') dockCat.classList.add('active');
}

/* ==========================================================
   3. DYNAMIC PLACE DETAILS VIEW
   ========================================================== */
function openPlace(placeId) {
  const item = campusPlaces[placeId];
  if (!item) return;

  const titleEl = document.getElementById('placeTitle');
  const subEl = document.getElementById('placeSub');
  const timeEl = document.getElementById('placeTime');
  const distEl = document.getElementById('placeDist');
  const hoursEl = document.getElementById('placeHours');
  const roomEl = document.getElementById('placeRoom');
  const inChargeEl = document.getElementById('placeInCharge');

  if (titleEl) titleEl.textContent = item.name;
  if (subEl) subEl.textContent = item.location;
  if (timeEl) timeEl.textContent = item.time;
  if (distEl) distEl.textContent = item.distance;
  if (hoursEl) hoursEl.textContent = item.hours;
  if (roomEl) roomEl.textContent = item.room;
  if (inChargeEl) inChargeEl.textContent = item.inCharge;

  // Banner image loader
  const bannerContainer = document.getElementById('placeBanner');
  if (bannerContainer) {
    if (item.bannerImg) {
      bannerContainer.innerHTML = `<img src="${item.bannerImg}" alt="${item.name}" style="width:100%; height:100%; object-fit:cover; border-radius:inherit; display:block;">`;
    } else {
      bannerContainer.innerHTML = `
        <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="#4d57c8" stroke-width="1.8">
          <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
          <polyline points="2 17 12 22 22 17"></polyline>
          <polyline points="2 12 12 17 22 12"></polyline>
        </svg>
      `;
    }
  }

  // Gallery loader
  const galleryContainer = document.getElementById('placeGallery');
  if (galleryContainer) {
    if (Array.isArray(item.gallery) && item.gallery.length > 0) {
      galleryContainer.innerHTML = item.gallery.map(src => `
        <div class="gallery-photo">
          <img src="${src}" alt="Place photo" style="width:100%; height:100%; object-fit:cover; border-radius:inherit; display:block;">
        </div>
      `).join('');
    } else {
      galleryContainer.innerHTML = `
        <div class="gallery-photo">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#8d99f3" stroke-width="1.8">
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
            <circle cx="8.5" cy="8.5" r="1.5"></circle>
            <polyline points="21 15 16 10 5 21"></polyline>
          </svg>
        </div>
        <div class="gallery-photo">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#8d99f3" stroke-width="1.8">
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
            <circle cx="8.5" cy="8.5" r="1.5"></circle>
            <polyline points="21 15 16 10 5 21"></polyline>
          </svg>
        </div>
        <div class="gallery-photo">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#8d99f3" stroke-width="1.8">
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
            <circle cx="8.5" cy="8.5" r="1.5"></circle>
            <polyline points="21 15 16 10 5 21"></polyline>
          </svg>
        </div>
      `;
    }
  }

  // Services loader
  const servicesContainer = document.getElementById('placeServicesList');
  if (servicesContainer) {
    if (Array.isArray(item.services) && item.services.length > 0) {
      servicesContainer.innerHTML = item.services.map(srv => `
        <div class="spec-list-row">
          <span class="spec-val" style="color: #2b3674; font-weight: 500;">• ${srv}</span>
        </div>
      `).join('');
    } else {
      servicesContainer.innerHTML = `
        <div class="spec-list-row">
          <span class="spec-val" style="color: #8d93aa;">No specific services listed.</span>
        </div>
      `;
    }
  }

  // Reset tab filter to "All"
  const tabAll = document.getElementById('tabAll');
  const tabServices = document.getElementById('tabServices');
  const secImg = document.getElementById('sectionImages');
  const secServ = document.getElementById('sectionServices');

  if (tabAll) tabAll.classList.add('active');
  if (tabServices) tabServices.classList.remove('active');
  if (secImg) secImg.style.display = 'block';
  if (secServ) secServ.style.display = 'block';

  navigateTo('viewPlaces');
}

/* ==========================================================
   4. TABS FILTER (All vs Services)
   ========================================================== */
function initPlaceFilterTabs() {
  const btnAll = document.getElementById('tabAll');
  const btnServices = document.getElementById('tabServices');
  const sectionImages = document.getElementById('sectionImages');
  const sectionServices = document.getElementById('sectionServices');

  if (!btnAll || !btnServices) return;

  btnAll.addEventListener('click', () => {
    btnAll.classList.add('active');
    btnServices.classList.remove('active');
    if (sectionImages) sectionImages.style.display = 'block';
    if (sectionServices) sectionServices.style.display = 'block';
  });

  btnServices.addEventListener('click', () => {
    btnServices.classList.add('active');
    btnAll.classList.remove('active');
    if (sectionImages) sectionImages.style.display = 'none';
    if (sectionServices) sectionServices.style.display = 'block';
  });
}

/* ==========================================================
   5. SEARCH FEED & FILTER LOGIC
   ========================================================== */
function renderSearchResults(filterText = '') {
  const container = document.getElementById('searchResults');
  if (!container) return;

  const q = filterText.toLowerCase().trim();
  const keys = Object.keys(campusPlaces);

  const matched = keys.filter(key => {
    const p = campusPlaces[key];
    const full = `${p.name} ${p.location} ${p.category || ''} ${p.desc || ''}`.toLowerCase();
    return full.includes(q);
  });

  if (matched.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding: 24px; color: #8d93aa; font-size: 13px;">No places found.</div>`;
    return;
  }

  container.innerHTML = matched.map(key => {
    const p = campusPlaces[key];
    return `
      <div class="search-result-card" onclick="openPlace('${key}')" style="cursor: pointer;">
        <div class="search-thumb-box">
          <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#4d57c8" stroke-width="1.8">
            <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
            <polyline points="2 17 12 22 22 17"></polyline>
            <polyline points="2 12 12 17 22 12"></polyline>
          </svg>
        </div>
        <div class="search-card-info">
          <h3>${p.name}</h3>
          <p>${p.location} • ${p.category || ''}</p>
        </div>
      </div>
    `;
  }).join('');
}

function initSearchInput() {
  const input = document.getElementById('liveSearchInput');
  if (!input) return;

  input.addEventListener('input', function () {
    renderSearchResults(this.value);
  });
}

function filterCategoryFromHome(categoryName) {
  const input = document.getElementById('liveSearchInput');
  if (input) input.value = categoryName;
  renderSearchResults(categoryName);
  navigateTo('viewSearch');
}

/* ==========================================================
   6. CATEGORIES LIVE FILTERING
   ========================================================== */
function initCategoriesPage() {
  const input = document.getElementById('catSearchInput');
  const categoryCards = document.querySelectorAll('.category-card');
  if (!input) return;

  input.addEventListener('input', function () {
    const query = this.value.toLowerCase().trim();
    categoryCards.forEach(card => {
      const heading = card.querySelector('h3') ? card.querySelector('h3').textContent.toLowerCase() : '';
      const paragraph = card.querySelector('p') ? card.querySelector('p').textContent.toLowerCase() : '';
      const fullText = heading + ' ' + paragraph;
      card.style.display = fullText.includes(query) ? 'flex' : 'none';
    });
  });
}

/* ==========================================================
   INITIALIZE ON DOM LOAD
   ========================================================== */
document.addEventListener('DOMContentLoaded', () => {
  initPlaceFilterTabs();
  initSearchInput();
  renderSearchResults(); // initial render
  initCategoriesPage();
});