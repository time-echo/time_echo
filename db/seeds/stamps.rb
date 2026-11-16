# frozen_string_literal: true

categories_data = [
  {
    slug: "small-things",
    name: { "en" => "Small Things", "es" => "Pequeñas cosas" },
    position: 1,
    active: true
  },
  {
    slug: "places-i-inhabit",
    name: { "en" => "Places I Inhabit", "es" => "Lugares que habito" },
    position: 2,
    active: true
  },
  {
    slug: "stored-thoughts",
    name: { "en" => "Stored Thoughts", "es" => "Pensamientos guardados" },
    position: 3,
    active: true
  },
  {
    slug: "passage-of-time",
    name: { "en" => "Passage of Time", "es" => "El paso del tiempo" },
    position: 4,
    active: true
  }
]

categories = {}
categories_data.each do |cat|
  record = StampCategory.find_or_initialize_by(slug: cat[:slug])
  record.update!(
    name: cat[:name],
    position: cat[:position],
    active: cat[:active]
  )
  categories[cat[:slug]] = record
end

stamps_data = [
  # Category: small-things
  {
    category_slug: "small-things",
    slug: "morning-coffee",
    name: { "en" => "Morning Coffee", "es" => "El café de la mañana" },
    position: 1,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <path d="M6 10L14 4" stroke-width="1" stroke-dasharray="2 3" opacity="0.6"/>
        <path d="M10 14L18 8" stroke-width="1" stroke-dasharray="2 3" opacity="0.6"/>
        <ellipse cx="23" cy="40" rx="17" ry="3.5" fill="currentColor" fill-opacity="0.12"/>
        <path d="M14 22V32C14 36 17 38 23 38C29 38 32 36 32 32V22H14Z" fill="currentColor" fill-opacity="0.18"/>
        <ellipse cx="23" cy="22" rx="9" ry="2.5"/>
        <path d="M32 24C35.5 24 37 26 37 28.5C37 31 35 33 32 33.5"/>
        <path d="M20 17C19 14 21 12 20 9" stroke-width="1.2"/>
        <path d="M24 16C23 13 25 11 24 8" stroke-width="1.2"/>
        <path d="M28 17C27 14 29 12 28 9" stroke-width="1.2"/>
        <ellipse cx="36" cy="38" rx="2" ry="1.2" transform="rotate(-25 36 38)" fill="currentColor" fill-opacity="0.3"/>
        <ellipse cx="10" cy="39" rx="1.8" ry="1" transform="rotate(30 10 39)" fill="currentColor" fill-opacity="0.3"/>
        <path d="M4 42H44" stroke-width="1" stroke-dasharray="3 3" opacity="0.4"/>
      </svg>
    SVG
  },
  {
    category_slug: "small-things",
    slug: "today-song",
    name: { "en" => "Today's Song", "es" => "La canción de hoy" },
    position: 2,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <rect x="9" y="18" width="30" height="20" rx="2" fill="currentColor" fill-opacity="0.15"/>
        <rect x="13" y="22" width="22" height="10" rx="1"/>
        <circle cx="19" cy="27" r="3.2" fill="currentColor" fill-opacity="0.25"/>
        <circle cx="29" cy="27" r="3.2" fill="currentColor" fill-opacity="0.25"/>
        <circle cx="19" cy="27" r="1.2" fill="currentColor"/>
        <circle cx="29" cy="27" r="1.2" fill="currentColor"/>
        <path d="M19 30H29" stroke-width="1"/>
        <path d="M15 35H33" stroke-width="0.9" stroke-dasharray="1.5 1.5"/>
        <path d="M12 20C12 11 36 11 36 20" stroke-width="1.4" stroke-dasharray="34"/>
        <rect x="8" y="19" width="4" height="7" rx="2" fill="currentColor" fill-opacity="0.25"/>
        <rect x="36" y="19" width="4" height="7" rx="2" fill="currentColor" fill-opacity="0.25"/>
        <path d="M24 10V6M22 6H26" stroke-width="1"/>
        <path d="M6 32C4 32 4 36 6 36" stroke-width="1"/>
        <path d="M42 32C44 32 44 36 42 36" stroke-width="1"/>
      </svg>
    SVG
  },
  {
    category_slug: "small-things",
    slug: "home-cooked-meal",
    name: { "en" => "The Usual", "es" => "Lo de siempre" },
    position: 3,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <ellipse cx="24" cy="38" rx="19" ry="5" fill="currentColor" fill-opacity="0.1"/>
        <path d="M11 26C11 34 16 37 24 37C32 37 37 34 37 26H11Z" fill="currentColor" fill-opacity="0.18"/>
        <ellipse cx="24" cy="26" rx="13" ry="4"/>
        <ellipse cx="24" cy="26" rx="10" ry="2.5" fill="currentColor" fill-opacity="0.25"/>
        <path d="M20 20C19 17 21 15 20 12" stroke-width="1.2"/>
        <path d="M24 19C23 16 25 14 24 11" stroke-width="1.2"/>
        <path d="M28 20C27 17 29 15 28 12" stroke-width="1.2"/>
        <path d="M37 28L42 22C43 21 44 22 43 23L38 31" stroke-width="1.3"/>
        <path d="M7 29C6 31 8 36 12 36C14 36 14 33 13 31C11 27 8 28 7 29Z" fill="currentColor" fill-opacity="0.2"/>
        <path d="M9 30L11 34" stroke-width="1"/>
        <path d="M5 43H43" stroke-width="1" stroke-dasharray="3 3" opacity="0.4"/>
      </svg>
    SVG
  },
  {
    category_slug: "small-things",
    slug: "todays-steps",
    name: { "en" => "Today's Steps", "es" => "Mis pasos de hoy" },
    position: 4,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <rect x="5" y="38" width="38" height="5" rx="1" fill="currentColor" fill-opacity="0.1"/>
        <path d="M8 40H40" stroke-width="1" stroke-dasharray="2 2" opacity="0.5"/>
        <g transform="translate(10, 16)">
          <path d="M3 18C3 13 7 11 9 11L12 15L16 16C19 17 20 19 20 22H1C1 20 2 19 3 18Z" fill="currentColor" fill-opacity="0.2"/>
          <rect x="1" y="21" width="19" height="2.5" rx="1"/>
          <path d="M7 14L10 17" stroke-width="1.1"/>
          <path d="M9 12L12 15" stroke-width="1.1"/>
          <circle cx="17" cy="19" r="1.5" fill="currentColor" fill-opacity="0.3"/>
        </g>
        <g transform="translate(23, 14)">
          <path d="M3 18C3 13 7 11 9 11L12 15L16 16C19 17 20 19 20 22H1C1 20 2 19 3 18Z" fill="currentColor" fill-opacity="0.2"/>
          <rect x="1" y="21" width="19" height="2.5" rx="1"/>
          <path d="M7 14L10 17" stroke-width="1.1"/>
          <path d="M9 12L12 15" stroke-width="1.1"/>
          <circle cx="17" cy="19" r="1.5" fill="currentColor" fill-opacity="0.3"/>
        </g>
        <path d="M24 6V11" stroke-width="1" stroke-dasharray="2 2" opacity="0.5"/>
        <path d="M22 8L24 6L26 8" stroke-width="1" opacity="0.5"/>
      </svg>
    SVG
  },
  {
    category_slug: "small-things",
    slug: "five-more-minutes",
    name: { "en" => "Five More Minutes", "es" => "Cinco minutos más" },
    position: 5,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="24" cy="22" r="12" fill="currentColor" fill-opacity="0.15"/>
        <circle cx="24" cy="22" r="10"/>
        <path d="M24 16V22L28 24" stroke-width="1.6"/>
        <circle cx="24" cy="22" r="1.2" fill="currentColor"/>
        <path d="M15 11C13 13 13 16 14 17" stroke-width="1.8"/>
        <path d="M33 11C35 13 35 16 34 17" stroke-width="1.8"/>
        <path d="M24 9V7" stroke-width="1.5"/>
        <path d="M21 7H27" stroke-width="1.5"/>
        <path d="M17 32L15 35" stroke-width="1.8"/>
        <path d="M31 32L33 35" stroke-width="1.8"/>
        <g transform="translate(10, 36)">
          <path d="M2 5C2 2 6 2 9 4C12 5 14 5 14 7H0C0 6 1 5 2 5Z" fill="currentColor" fill-opacity="0.22"/>
          <path d="M0 7H14" stroke-width="1.3"/>
        </g>
        <g transform="translate(26, 36)">
          <path d="M2 5C2 2 6 2 9 4C12 5 14 5 14 7H0C0 6 1 5 2 5Z" fill="currentColor" fill-opacity="0.22"/>
          <path d="M0 7H14" stroke-width="1.3"/>
        </g>
        <path d="M8 20C6 19 6 23 8 22" stroke-width="1" opacity="0.6"/>
        <path d="M40 20C42 19 42 23 40 22" stroke-width="1" opacity="0.6"/>
      </svg>
    SVG
  },
  {
    category_slug: "small-things",
    slug: "todays-list",
    name: { "en" => "Today's List", "es" => "La lista de hoy" },
    position: 6,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 7H34C35.1 7 36 7.9 36 9V39C36 40.1 35.1 41 34 41H12C10.9 41 10 40.1 10 39V9C10 7.9 10.9 7 12 7Z" fill="currentColor" fill-opacity="0.14"/>
        <path d="M10 12H36" stroke-width="0.8" opacity="0.5"/>
        <rect x="14" y="16" width="3.5" height="3.5" rx="0.5"/>
        <path d="M14.5 17.5L16 19L19.5 15" stroke-width="1.2"/>
        <path d="M20 18H31" stroke-width="1.2"/>
        <rect x="14" y="23" width="3.5" height="3.5" rx="0.5"/>
        <path d="M14.5 24.5L16 26L19.5 22" stroke-width="1.2"/>
        <path d="M20 25H29" stroke-width="1.2"/>
        <rect x="14" y="30" width="3.5" height="3.5" rx="0.5"/>
        <path d="M20 32H32" stroke-width="1.2" stroke-dasharray="1.5 2"/>
        <g transform="translate(30, 24) rotate(42)">
          <rect x="0" y="0" width="3" height="15" fill="currentColor" fill-opacity="0.25" stroke-width="1"/>
          <polygon points="0,15 1.5,19 3,15" fill="currentColor"/>
          <line x1="0" y1="3" x2="3" y2="3" stroke-width="1"/>
        </g>
      </svg>
    SVG
  },

  # Category: places-i-inhabit
  {
    category_slug: "places-i-inhabit",
    slug: "little-home",
    name: { "en" => "My Little Home", "es" => "Mi pequeño hogar" },
    position: 1,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <polygon points="10,21 24,9 38,21" fill="currentColor" fill-opacity="0.2"/>
        <rect x="29" y="8" width="4" height="7" fill="currentColor" fill-opacity="0.15"/>
        <path d="M31 6C31 4 33 4 33 2" stroke-width="1" stroke-dasharray="1.5 2"/>
        <rect x="13" y="21" width="22" height="18" fill="currentColor" fill-opacity="0.1"/>
        <rect x="21" y="27" width="6" height="12" fill="currentColor" fill-opacity="0.25"/>
        <circle cx="25.5" cy="33" r="0.6" fill="currentColor"/>
        <rect x="15" y="24" width="4" height="5"/>
        <line x1="17" y1="24" x2="17" y2="29" stroke-width="0.8"/>
        <line x1="15" y1="26.5" x2="19" y2="26.5" stroke-width="0.8"/>
        <rect x="29" y="24" width="4" height="5"/>
        <line x1="31" y1="24" x2="31" y2="29" stroke-width="0.8"/>
        <line x1="29" y1="26.5" x2="33" y2="26.5" stroke-width="0.8"/>
        <path d="M7 23C7 19 12 18 12 21C12 24 7 24 7 23Z" fill="currentColor" fill-opacity="0.3"/>
        <line x1="9.5" y1="23" x2="9.5" y2="39" stroke-width="1.2"/>
        <path d="M36 29C38 29 44 27 44 27" stroke-width="0.9" stroke-dasharray="1.5 1.5"/>
        <path d="M38 28.5L39 33" stroke-width="1"/>
        <path d="M41 28L42 32" stroke-width="1"/>
        <path d="M4 39H44" stroke-width="1.4"/>
        <circle cx="17" cy="37" r="1.5" fill="currentColor" fill-opacity="0.4"/>
        <circle cx="31" cy="37" r="1.5" fill="currentColor" fill-opacity="0.4"/>
      </svg>
    SVG
  },
  {
    category_slug: "places-i-inhabit",
    slug: "neighborhood-corner",
    name: { "en" => "The Usual Spot", "es" => "Mi lugar de siempre" },
    position: 2,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <rect x="6" y="8" width="36" height="10" fill="currentColor" fill-opacity="0.15"/>
        <path d="M6 18L10 12M12 18L16 12M18 18L22 12M24 18L28 12M30 18L34 12M36 18L40 12" stroke-width="1"/>
        <path d="M6 18C8 19.5 10 19.5 12 18C14 19.5 16 19.5 18 18C20 19.5 22 19.5 24 18C26 19.5 28 19.5 30 18C32 19.5 34 19.5 36 18C38 19.5 40 19.5 42 18" stroke-width="1"/>
        <rect x="10" y="20" width="12" height="12" fill="currentColor" fill-opacity="0.08"/>
        <line x1="16" y1="20" x2="16" y2="32" stroke-width="0.8"/>
        <line x1="10" y1="26" x2="22" y2="26" stroke-width="0.8"/>
        <g transform="translate(18, 25)">
          <circle cx="6" cy="11" r="5" fill="currentColor" fill-opacity="0.15"/>
          <circle cx="20" cy="11" r="5" fill="currentColor" fill-opacity="0.15"/>
          <circle cx="6" cy="11" r="1.2" fill="currentColor"/>
          <circle cx="20" cy="11" r="1.2" fill="currentColor"/>
          <path d="M6 11L11 6L16 11H6Z" stroke-width="1.2"/>
          <path d="M11 6L11 3M9 3H13" stroke-width="1.2"/>
          <path d="M16 11L18 4" stroke-width="1.2"/>
          <path d="M17 4H20" stroke-width="1.3"/>
          <rect x="19" y="3" width="4" height="3" rx="0.5" stroke-width="0.9" fill="currentColor" fill-opacity="0.3"/>
        </g>
        <path d="M4 42H44" stroke-width="1.4"/>
      </svg>
    SVG
  },
  {
    category_slug: "places-i-inhabit",
    slug: "way-home",
    name: { "en" => "The Way Home", "es" => "Camino a casa" },
    position: 3,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <path d="M10 16L30 14L32 18L10 20Z" fill="currentColor" fill-opacity="0.25"/>
        <line x1="12" y1="20" x2="12" y2="38" stroke-width="1.4"/>
        <line x1="28" y1="18" x2="28" y2="38" stroke-width="1.4"/>
        <rect x="14" y="28" width="12" height="2" rx="0.5" fill="currentColor" fill-opacity="0.3"/>
        <line x1="16" y1="30" x2="16" y2="38" stroke-width="1.1"/>
        <line x1="24" y1="30" x2="24" y2="38" stroke-width="1.1"/>
        <rect x="15" y="21" width="6" height="5" rx="0.5" stroke-width="0.9"/>
        <line x1="36" y1="8" x2="36" y2="38" stroke-width="1.4"/>
        <path d="M36 10C36 8 39 7 40 9C41 10 40 12 36 12" stroke-width="1.3"/>
        <circle cx="39" cy="10" r="1.5" fill="currentColor"/>
        <path d="M37 13L42 22" stroke-width="0.8" stroke-dasharray="1.5 2" opacity="0.4"/>
        <path d="M4 38H44" stroke-width="1.4"/>
        <path d="M4 42H44" stroke-width="1" stroke-dasharray="3 3" opacity="0.4"/>
      </svg>
    SVG
  },
  {
    category_slug: "places-i-inhabit",
    slug: "favorite-spot",
    name: { "en" => "Favorite Haven", "es" => "Mi lugar favorito" },
    position: 4,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <path d="M8 10H40V16C40 18 8 18 8 16V10Z" fill="currentColor" fill-opacity="0.2"/>
        <path d="M12 10V16M16 10V16M20 10V16M24 10V16M28 10V16M32 10V16M36 10V16" stroke-width="0.8" opacity="0.6"/>
        <rect x="10" y="18" width="16" height="14" fill="currentColor" fill-opacity="0.08"/>
        <line x1="10" y1="24" x2="26" y2="24" stroke-width="0.8"/>
        <line x1="18" y1="18" x2="18" y2="32" stroke-width="0.8"/>
        <path d="M12 28L15 26L16 28" stroke-width="1"/>
        <path d="M20 28C21 26 23 26 24 28" stroke-width="1"/>
        <rect x="29" y="18" width="10" height="20" fill="currentColor" fill-opacity="0.15"/>
        <circle cx="37" cy="28" r="0.8" fill="currentColor"/>
        <rect x="31" y="21" width="6" height="6" stroke-width="0.9"/>
        <g transform="translate(6, 32)">
          <ellipse cx="6" cy="4" rx="4" ry="1.2" fill="currentColor" fill-opacity="0.3"/>
          <line x1="6" y1="4" x2="6" y2="8" stroke-width="1"/>
          <line x1="4" y1="8" x2="8" y2="8" stroke-width="1"/>
        </g>
        <path d="M4 39H44" stroke-width="1.4"/>
        <path d="M15 14H21" stroke-width="1"/>
      </svg>
    SVG
  },

  # Category: stored-thoughts
  {
    category_slug: "stored-thoughts",
    slug: "rainy-afternoon",
    name: { "en" => "A Rainy Afternoon", "es" => "Una tarde lluviosa" },
    position: 1,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <rect x="10" y="8" width="28" height="28" rx="1" fill="currentColor" fill-opacity="0.12"/>
        <line x1="24" y1="8" x2="24" y2="36" stroke-width="1.6"/>
        <line x1="10" y1="22" x2="38" y2="22" stroke-width="1.6"/>
        <line x1="14" y1="12" x2="16" y2="17" stroke-width="1" stroke-dasharray="1.5 2" opacity="0.6"/>
        <line x1="28" y1="11" x2="31" y2="18" stroke-width="1" stroke-dasharray="1.5 2" opacity="0.6"/>
        <line x1="16" y1="25" x2="19" y2="32" stroke-width="1" stroke-dasharray="1.5 2" opacity="0.6"/>
        <line x1="30" y1="26" x2="33" y2="33" stroke-width="1" stroke-dasharray="1.5 2" opacity="0.6"/>
        <rect x="7" y="36" width="34" height="4" rx="1" fill="currentColor" fill-opacity="0.3"/>
        <rect x="29" y="30" width="4" height="6" rx="0.5" fill="currentColor" fill-opacity="0.25"/>
        <path d="M31 30C30 28 32 26 31 24C30 26 32 28 31 30Z" fill="currentColor"/>
        <path d="M7 8C10 14 10 20 8 26" stroke-width="1.2"/>
        <circle cx="13" cy="27" r="0.8" fill="currentColor" opacity="0.7"/>
        <circle cx="26" cy="15" r="0.8" fill="currentColor" opacity="0.7"/>
        <circle cx="34" cy="29" r="0.8" fill="currentColor" opacity="0.7"/>
      </svg>
    SVG
  },
  {
    category_slug: "stored-thoughts",
    slug: "personal-journal",
    name: { "en" => "My Personal Journal", "es" => "Mi diario personal" },
    position: 2,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <path d="M8 12C14 10 20 12 24 14C28 12 34 10 40 12V36C34 34 28 36 24 38C20 36 14 34 8 36V12Z" fill="currentColor" fill-opacity="0.14"/>
        <line x1="24" y1="14" x2="24" y2="38" stroke-width="1.6"/>
        <path d="M12 17C16 16 19 17 21 18" stroke-width="0.9" opacity="0.6"/>
        <path d="M12 22C16 21 19 22 21 23" stroke-width="0.9" opacity="0.6"/>
        <path d="M12 27C16 26 19 27 21 28" stroke-width="0.9" opacity="0.6"/>
        <path d="M12 32C16 31 19 32 21 33" stroke-width="0.9" opacity="0.6"/>
        <path d="M27 18C29 17 32 16 36 17" stroke-width="0.9" opacity="0.6"/>
        <path d="M27 23C29 22 32 21 36 22" stroke-width="0.9" opacity="0.6"/>
        <g transform="translate(30, 24)">
          <path d="M3 11C2 8 4 5 5 2" stroke-width="1"/>
          <circle cx="5" cy="2" r="1.5" fill="currentColor"/>
          <ellipse cx="3" cy="1" rx="1.5" ry="0.8" transform="rotate(-30 3 1)" fill="currentColor" fill-opacity="0.4"/>
          <ellipse cx="7" cy="1" rx="1.5" ry="0.8" transform="rotate(30 7 1)" fill="currentColor" fill-opacity="0.4"/>
        </g>
        <g transform="translate(18, 6) rotate(35)">
          <rect x="0" y="0" width="2.5" height="24" fill="currentColor" fill-opacity="0.3" stroke-width="1"/>
          <polygon points="0,24 1.25,28 2.5,24" fill="currentColor"/>
        </g>
      </svg>
    SVG
  },
  {
    category_slug: "stored-thoughts",
    slug: "ordinary-day",
    name: { "en" => "An Ordinary Day", "es" => "Un día cualquiera" },
    position: 3,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <rect x="8" y="18" width="32" height="22" rx="3" fill="currentColor" fill-opacity="0.16"/>
        <line x1="8" y1="24" x2="40" y2="24" stroke-width="1"/>
        <circle cx="24" cy="30" r="7" fill="currentColor" fill-opacity="0.2"/>
        <circle cx="24" cy="30" r="4.5"/>
        <circle cx="24" cy="30" r="1.5" fill="currentColor"/>
        <rect x="13" y="14" width="6" height="4" rx="1" fill="currentColor" fill-opacity="0.3"/>
        <circle cx="33" cy="21" r="1.5" fill="currentColor"/>
        <rect x="12" y="21" width="3" height="1.5" rx="0.5" fill="currentColor"/>
        <g transform="translate(18, 4)">
          <rect x="0" y="0" width="12" height="14" rx="1" fill="currentColor" fill-opacity="0.25" stroke-width="1"/>
          <rect x="1.5" y="1.5" width="9" height="8" fill="currentColor" fill-opacity="0.4" stroke-width="0.6"/>
          <path d="M3 8L6 5L9 8" stroke-width="0.8"/>
          <circle cx="8" cy="4" r="0.8" fill="currentColor"/>
        </g>
      </svg>
    SVG
  },
  {
    category_slug: "stored-thoughts",
    slug: "work-in-progress",
    name: { "en" => "Work in Progress", "es" => "En lo que estoy trabajando" },
    position: 4,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <ellipse cx="12" cy="35" rx="3" ry="1.5"/>
        <path d="M12 35L14 24L10 16" stroke-width="1.4"/>
        <path d="M8 16L15 13L16 18L10 19Z" fill="currentColor" fill-opacity="0.3" stroke-width="1.2"/>
        <path d="M14 18L18 28" stroke-width="0.8" stroke-dasharray="1.5 2" opacity="0.4"/>
        <path d="M20 23L33 23L36 34L17 34Z" fill="currentColor" fill-opacity="0.18"/>
        <rect x="16" y="34" width="22" height="2" rx="0.5" fill="currentColor" fill-opacity="0.3"/>
        <line x1="22" y1="28" x2="31" y2="28" stroke-width="0.8" opacity="0.5"/>
        <g transform="translate(35, 27) rotate(-15)">
          <rect x="0" y="0" width="8" height="10" rx="0.5" fill="currentColor" fill-opacity="0.2" stroke-width="1"/>
          <line x1="0" y1="2" x2="2" y2="2" stroke-width="0.8"/>
          <line x1="0" y1="5" x2="2" y2="5" stroke-width="0.8"/>
          <line x1="0" y1="8" x2="2" y2="8" stroke-width="0.8"/>
        </g>
        <path d="M4 36H44" stroke-width="1.4"/>
      </svg>
    SVG
  },

  # Category: passage-of-time
  {
    category_slug: "passage-of-time",
    slug: "something-growing",
    name: { "en" => "Something Growing", "es" => "Algo está creciendo" },
    position: 1,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <rect x="15" y="27" width="18" height="3" rx="0.5" fill="currentColor" fill-opacity="0.25"/>
        <path d="M17 30L19 40H29L31 30" fill="currentColor" fill-opacity="0.18"/>
        <ellipse cx="24" cy="30" rx="7" ry="1.5" fill="currentColor" fill-opacity="0.35"/>
        <path d="M24 30V18" stroke-width="1.6"/>
        <path d="M24 23C27 21 31 22 32 25C29 26 26 25 24 23Z" fill="currentColor" fill-opacity="0.25"/>
        <path d="M24 18C21 15 16 16 15 19C18 20 22 19 24 18Z" fill="currentColor" fill-opacity="0.3"/>
        <path d="M24 18C25 13 28 10 30 11C30 14 27 17 24 18Z" fill="currentColor" fill-opacity="0.35"/>
        <circle cx="10" cy="12" r="1.5" stroke-dasharray="1.5 2" opacity="0.5"/>
        <path d="M10 8V6M10 16V18M6 12H4M14 12H16" stroke-width="0.8" opacity="0.5"/>
        <path d="M6 42H42" stroke-width="1.2" stroke-dasharray="3 3" opacity="0.4"/>
      </svg>
    SVG
  },
  {
    category_slug: "passage-of-time",
    slug: "first-key",
    name: { "en" => "My First Key", "es" => "Mi primera llave" },
    position: 2,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <g transform="translate(8, 8)">
          <circle cx="10" cy="10" r="7" fill="currentColor" fill-opacity="0.18"/>
          <circle cx="10" cy="10" r="3.5" fill="currentColor" fill-opacity="0.2"/>
          <path d="M15 15L31 31" stroke-width="2.2"/>
          <path d="M25 25L28 22" stroke-width="1.8"/>
          <path d="M28 28L31 25" stroke-width="1.8"/>
          <path d="M30 30L33 27" stroke-width="1.8"/>
          <path d="M6 6C3 4 2 8 1 12" stroke-width="1.2" stroke-dasharray="2 2"/>
          <path d="M7 14C5 17 8 20 10 22" stroke-width="1.2" stroke-dasharray="2 2"/>
        </g>
        <path d="M4 41C16 39 32 43 44 41" stroke-width="1" stroke-dasharray="4 4" opacity="0.5"/>
        <path d="M6 44C20 42 28 46 42 44" stroke-width="1" stroke-dasharray="4 4" opacity="0.5"/>
      </svg>
    SVG
  },
  {
    category_slug: "passage-of-time",
    slug: "one-more-year",
    name: { "en" => "One More Year", "es" => "Un año más" },
    position: 3,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <ellipse cx="24" cy="38" rx="16" ry="3.5" fill="currentColor" fill-opacity="0.1"/>
        <ellipse cx="24" cy="38" rx="14" ry="2"/>
        <path d="M13 28V36C13 38 18 39 24 39C30 39 35 38 35 36V28H13Z" fill="currentColor" fill-opacity="0.18"/>
        <ellipse cx="24" cy="28" rx="11" ry="3.5" fill="currentColor" fill-opacity="0.25"/>
        <path d="M13 28C14 29.5 16 29.5 17 28C18 29.5 20 29.5 21 28C22 29.5 24 29.5 25 28C26 29.5 28 29.5 29 28C30 29.5 32 29.5 33 28C34 29.5 35 29 35 28" stroke-width="1.2"/>
        <rect x="23" y="16" width="2" height="9" rx="0.5" fill="currentColor" fill-opacity="0.35"/>
        <path d="M24 15C22 13 23 10 24 8C25 10 26 13 24 15Z" fill="currentColor" stroke-width="1"/>
        <circle cx="16" cy="15" r="0.8" fill="currentColor" opacity="0.5"/>
        <circle cx="32" cy="14" r="0.8" fill="currentColor" opacity="0.5"/>
        <circle cx="29" cy="9" r="0.6" fill="currentColor" opacity="0.5"/>
        <circle cx="19" cy="10" r="0.6" fill="currentColor" opacity="0.5"/>
      </svg>
    SVG
  },
  {
    category_slug: "passage-of-time",
    slug: "little-companion",
    name: { "en" => "Little Companion", "es" => "Mi pequeño compañero" },
    position: 4,
    active: true,
    svg_content: <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 28V36C12 39 16 40 22 40C28 40 32 39 32 36V28H12Z" fill="currentColor" fill-opacity="0.2"/>
        <ellipse cx="22" cy="28" rx="10" ry="2.5"/>
        <path d="M32 30C34.5 30 35.5 31.5 35.5 33.5C35.5 35.5 34.5 37 32 37" stroke-width="1.2"/>
        <g transform="translate(14, 12)">
          <path d="M8 14C8 10 11 8 13 11C15 14 13 16 8 16Z" fill="currentColor" fill-opacity="0.3"/>
          <path d="M8 14C8 10 5 8 3 11C1 14 3 16 8 16Z" fill="currentColor" fill-opacity="0.3"/>
          <path d="M8 13C6 8 10 6 12 7C14 10 10 13 8 13Z" fill="currentColor" fill-opacity="0.35"/>
          <path d="M8 13C10 8 6 6 4 7C2 10 6 13 8 13Z" fill="currentColor" fill-opacity="0.35"/>
          <ellipse cx="8" cy="8" rx="2.5" ry="4" fill="currentColor" fill-opacity="0.4"/>
        </g>
        <g transform="translate(24, 34)">
          <circle cx="5" cy="5" r="3" stroke-width="1"/>
          <circle cx="13" cy="5" r="3" stroke-width="1"/>
          <line x1="8" y1="5" x2="10" y2="5" stroke-width="1"/>
          <path d="M2 5L0 3" stroke-width="0.8"/>
          <path d="M16 5L18 3" stroke-width="0.8"/>
        </g>
        <path d="M6 42H42" stroke-width="1" stroke-dasharray="3 3" opacity="0.4"/>
      </svg>
    SVG
  }
]

stamps_data.each do |stamp|
  cat = categories[stamp[:category_slug]]
  record = Stamp.find_or_initialize_by(slug: stamp[:slug])
  record.update!(
    stamp_category: cat,
    name: stamp[:name],
    position: stamp[:position],
    active: stamp[:active],
    svg_content: stamp[:svg_content]
  )
end

puts "Seeded #{StampCategory.count} stamp categories and #{Stamp.count} stamps."
