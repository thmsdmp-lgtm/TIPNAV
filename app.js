/* ==========================================================
   1. DATABASE NG CAMPUS PLACES
   DITO I-INPUT LAHAT NG PLACES INFOS DEETS SAKA IMAGES PARA ISA LANG ANG PLACES.HTML
   ========================================================== */
const campusPlaces = {
  "placeh1": {
    name: "Placeholder 1",
    category: "blablabla",
    location: "blablabla",
    time: "blablabla",
    distance: "blablabla",
    hours: "blablabla",
    room: "blablabla",
    inCharge: "blablabla",
    contact: "blablabla",
    desc: "blablabla",
    bannerImg: null,
    gallery: null,
    // DITO ILALAGAY SERVICES:
    services: [
      "dasdasdasdaw",
      "dsadsadsadasdsa",
      "dsadasdsadasdsa",
      "sadasdsad"
    ]
  },
  "placeh2": {
    name: "Placeholder 2",
    category: "blablabla",
    location: "blablabla",
    time: "blablabla",
    distance: "blablabla",
    hours: "blablabla",
    room: "blablabla",
    inCharge: "blablabla",
    contact: "blablabla",
    desc: "blablabla",
    bannerImg: null,
    gallery: null
  },
  "placeh3": {
    name: "Placeholder 3",
    category: "blablabla",
    location: "blablabla",
    time: "blablabla",
    distance: "blablabla",
    hours: "blablabla",
    room: "blablabla",
    inCharge: "blablabla",
    contact: "blablabla",
    desc: "blablabla",
    bannerImg: null,
    gallery: null
  },
  "placeh4": {
    name: "Placeholder 4",
    category: "blablabla",
    location: "blablabla",
    time: "blablabla",
    distance: "blablabla",
    hours: "blablabla",
    room: "blablabla",
    inCharge: "blablabla",
    contact: "blablabla",
    desc: "blablabla",
    bannerImg: null,
    gallery: null
  }
};

/* ==========================================================
   2. HIGHLIGHTS THE FOOTER OF THE ACTIVE TAB
   ========================================================== */
function setupActiveDock() {
  const currentPath = decodeURIComponent(window.location.pathname.toLowerCase());
  const navLinks = document.querySelectorAll('.footer-nav .nav-link');

  navLinks.forEach(link => {
    const rawHref = link.getAttribute('href');
    if (!rawHref) return;

    const href = decodeURIComponent(rawHref.toLowerCase());

    if (
      (currentPath.endsWith('/') || currentPath.endsWith('index.html')) &&
      href.includes('index.html')
    ) {
      link.classList.add('active');
    } else if (currentPath.includes('category.html') && href.includes('category.html')) {
      link.classList.add('active');
    } else if (currentPath.includes('map page.html') && href.includes('map page.html')) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });
}

/* ==========================================================
   3. GLOBAL SEARCH BAR REDIRECT
   ========================================================== */
function setupSearchRedirects() {
  const currentPath = window.location.pathname.toLowerCase();

  // If already on Category.html or search.html, do NOT hijack inputs
  if (currentPath.includes('category.html') || currentPath.includes('search.html')) {
    return;
  }

  const searchBars = document.querySelectorAll(
    '.open-search-trigger, .search-box, .map-search-bar'
  );

  searchBars.forEach(bar => {
    // If the bar is inside places.html top nav, skip it since it uses a direct <a> tag
    if (bar.classList.contains('place-search-link') || bar.closest('.place-top-nav')) {
      return;
    }

    bar.style.cursor = 'pointer';
    const input = bar.querySelector('input');
    if (input) {
      input.setAttribute('readonly', 'true');
      input.style.cursor = 'pointer';
    }

    bar.addEventListener('click', (e) => {
      e.preventDefault();
      window.location.href = 'search.html';
    });
  });
}

/* ==========================================================
	  4. DYNAMIC PLACES PAGE LOADER (places.html)
   ========================================================== */
function initPlacesPage() {
  const titleEl = document.getElementById('placeTitle');
  if (!titleEl) return; // Exit if not on places.html

  const params = new URLSearchParams(window.location.search);
  const placeId = params.get('id');

  if (placeId && campusPlaces[placeId]) {
    const item = campusPlaces[placeId];

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

    // Swap banner image if available
    const bannerContainer = document.getElementById('placeBanner');
    if (bannerContainer && item.bannerImg) {
      bannerContainer.innerHTML = `<img src="${item.bannerImg}" alt="${item.name}" style="width:100%; height:100%; object-fit:cover; border-radius:inherit; display:block;">`;
    }

    // Swap gallery images if available
    const galleryContainer = document.getElementById('placeGallery');
    if (galleryContainer && Array.isArray(item.gallery) && item.gallery.length > 0) {
      galleryContainer.innerHTML = item.gallery.map(src => `
        <div class="gallery-photo">
          <img src="${src}" alt="Place photo" style="width:100%; height:100%; object-fit:cover; border-radius:inherit; display:block;">
        </div>
      `).join('');
    }

    // --- INSERTED HERE: Swap services list if available ---
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
  }
}

/* ==========================================================
   5. PLACES PAGE FILTER TABS (All and Services)
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

    // Hide images, prioritize details/services
    if (sectionImages) sectionImages.style.display = 'none';
    if (sectionServices) sectionServices.style.display = 'block';
  });
}

/* ==========================================================
  5. SEARCH PAGE DYNAMIC FEED & LIVE FILTER (search.html)
   ========================================================== */
function initSearchPage() {
  const input = document.getElementById('liveSearchInput');
  const resultsContainer = document.getElementById('searchResults');
  if (!resultsContainer) return;

  function renderCards(filterText = '') {
    const q = filterText.toLowerCase().trim();
    const keys = Object.keys(campusPlaces);

    const matches = keys.filter(key => {
      const p = campusPlaces[key];
      const full = `${p.name} ${p.location} ${p.category || ''} ${p.desc || ''}`.toLowerCase();
      return full.includes(q);
    });

    if (matches.length === 0) {
      resultsContainer.innerHTML = `<div style="text-align:center; padding: 24px; color: #8d93aa; font-size: 13px;">No places found.</div>`;
      return;
    }

    resultsContainer.innerHTML = matches.map(key => {
      const p = campusPlaces[key];
      return `
        <a href="places.html?id=${key}" class="search-result-card">
          <div class="search-thumb-box">
            <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#4d57c8" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
              <polyline points="2 17 12 22 22 17"></polyline>
              <polyline points="2 12 12 17 22 12"></polyline>
            </svg>
          </div>
          <div class="search-card-info">
            <h3>${p.name}</h3>
            <p>${p.location}</p>
          </div>
        </a>
      `;
    }).join('');
  }

  // Handle URL category param if present
  const params = new URLSearchParams(window.location.search);
  const catParam = params.get('cat') || '';
  if (input && catParam) {
    input.value = catParam;
  }
  renderCards(catParam);

  if (input) {
    input.addEventListener('input', function () {
      renderCards(this.value);
    });
  }
}

/* ==========================================================
   7. CATEGORIES PAGE LIVE FILTERING (Category.html)
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
  setupActiveDock();
  setupSearchRedirects();
  initPlacesPage();
  initPlaceFilterTabs();
  initSearchPage();
  initCategoriesPage();
});