# frozen_string_literal: true

categories_data = [
  {
    slug: "future-reflections",
    name: { "en" => "Future Reflections", "es" => "Reflexiones del futuro" },
    description: {
      "en" => "Thoughts about the person you hope to become.",
      "es" => "Pensamientos sobre la persona en la que esperas convertirte."
    },
    position: 1,
    active: true
  },
  {
    slug: "dreams-goals",
    name: { "en" => "Dreams & Goals", "es" => "Sueños y metas" },
    description: {
      "en" => "Personal ambitions, plans, and aspirations.",
      "es" => "Ambiciones personales, planes y aspiraciones."
    },
    position: 2,
    active: true
  },
  {
    slug: "relationships",
    name: { "en" => "Relationships", "es" => "Relaciones" },
    description: {
      "en" => "Family, friends, meaningful connections, and loved ones.",
      "es" => "Familia, amistades, vínculos significativos y seres queridos."
    },
    position: 3,
    active: true
  },
  {
    slug: "everyday-life",
    name: { "en" => "Everyday Life", "es" => "Vida cotidiana" },
    description: {
      "en" => "Current routines, experiences, interests, and daily life.",
      "es" => "Rutinas actuales, experiencias, intereses y el día a día."
    },
    position: 4,
    active: true
  },
  {
    slug: "personal-growth",
    name: { "en" => "Personal Growth", "es" => "Crecimiento personal" },
    description: {
      "en" => "Lessons, challenges, fears, and self-improvement.",
      "es" => "Lecciones, desafíos, miedos y evolución personal."
    },
    position: 5,
    active: true
  },
  {
    slug: "gratitude",
    name: { "en" => "Gratitude", "es" => "Gratitud" },
    description: {
      "en" => "Things, people, and moments you appreciate.",
      "es" => "Cosas, personas y momentos que agradeces."
    },
    position: 6,
    active: true
  },
  {
    slug: "predictions",
    name: { "en" => "Predictions", "es" => "Predicciones" },
    description: {
      "en" => "Expectations and predictions about your future.",
      "es" => "Expectativas y pronósticos sobre tu futuro."
    },
    position: 7,
    active: true
  },
  {
    slug: "just-because",
    name: { "en" => "Just Because", "es" => "Porque sí" },
    description: {
      "en" => "Open-ended and spontaneous writing ideas.",
      "es" => "Ideas abiertas y espontáneas para escribir sin plan."
    },
    position: 8,
    active: true
  }
]

categories = {}
categories_data.each do |cat|
  record = InspirationCategory.find_or_initialize_by(slug: cat[:slug])
  record.update!(
    name: cat[:name],
    description: cat[:description],
    position: cat[:position],
    active: cat[:active]
  )
  categories[cat[:slug]] = record
end

inspirations_data = [
  # Category: future-reflections
  {
    category_slug: "future-reflections",
    slug: "person-to-become",
    text: {
      "en" => "What kind of person do you hope to become?",
      "es" => "¿Qué tipo de persona esperas llegar a ser?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "future-reflections",
    slug: "advice-to-future",
    text: {
      "en" => "What advice would you give your future self?",
      "es" => "¿Qué consejo le darías a tu yo del futuro?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "future-reflections",
    slug: "hope-never-changes",
    text: {
      "en" => "What part of who you are today do you hope never changes?",
      "es" => "¿Qué parte de quien eres hoy esperas que nunca cambie?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "future-reflections",
    slug: "proud-to-hear",
    text: {
      "en" => "What would make your future self smile when reading this?",
      "es" => "¿Qué haría sonreír a tu yo del futuro al leer esta carta?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "future-reflections",
    slug: "letter-to-remember",
    text: {
      "en" => "If you could remind your future self of one truth today, what would it be?",
      "es" => "Si pudieras recordarle una sola verdad a tu yo del futuro hoy, ¿cuál sería?"
    },
    position: 5,
    active: true
  },

  # Category: dreams-goals
  {
    category_slug: "dreams-goals",
    slug: "three-accomplishments",
    text: {
      "en" => "What are three things you want to accomplish?",
      "es" => "¿Cuáles son tres cosas que quieres lograr?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "dreams-goals",
    slug: "dream-too-big",
    text: {
      "en" => "What dream feels a little intimidating right now, but still excites you?",
      "es" => "¿Qué sueño te da un poco de vértigo ahora mismo, pero te ilusiona igual?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "dreams-goals",
    slug: "next-chapter",
    text: {
      "en" => "What do you hope the next chapter of your life looks like?",
      "es" => "¿Cómo te gustaría que se vea el próximo capítulo de tu vida?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "dreams-goals",
    slug: "skill-to-master",
    text: {
      "en" => "What skill, craft, or habit do you want to build over the next year?",
      "es" => "¿Qué habilidad, oficio o hábito quieres construir durante el próximo año?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "dreams-goals",
    slug: "courageous-step",
    text: {
      "en" => "What is one brave step you have been putting off?",
      "es" => "¿Cuál es ese paso valiente que has estado postergando?"
    },
    position: 5,
    active: true
  },

  # Category: relationships
  {
    category_slug: "relationships",
    slug: "people-who-matter",
    text: {
      "en" => "Who are the people shaping your life right now, and why do they matter to you?",
      "es" => "¿Quiénes son las personas que marcan tu vida hoy y por qué son importantes para ti?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "relationships",
    slug: "unsaid-thank-you",
    text: {
      "en" => "Who deserves a thank you you haven't said out loud yet?",
      "es" => "¿Quién merece un agradecimiento que todavía no le has dicho en voz alta?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "relationships",
    slug: "hope-still-close",
    text: {
      "en" => "Who do you hope is still by your side when you open this letter?",
      "es" => "¿A quién esperas seguir teniendo cerca cuando abras esta carta?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "relationships",
    slug: "favorite-conversation",
    text: {
      "en" => "What recent conversation stayed with you long after it ended?",
      "es" => "¿Qué conversación reciente se quedó contigo mucho después de terminar?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "relationships",
    slug: "how-you-love",
    text: {
      "en" => "How have your closest relationships changed you lately?",
      "es" => "¿Cómo te han transformado últimamente tus vínculos más cercanos?"
    },
    position: 5,
    active: true
  },

  # Category: everyday-life
  {
    category_slug: "everyday-life",
    slug: "little-things-happy",
    text: {
      "en" => "What little things make you happy right now?",
      "es" => "¿Qué pequeñas cosas te hacen feliz en este momento?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "everyday-life",
    slug: "ordinary-day",
    text: {
      "en" => "Describe an ordinary day in your life right now—from morning to night.",
      "es" => "Describe un día cualquiera de tu vida hoy, desde la mañana hasta la noche."
    },
    position: 2,
    active: true
  },
  {
    category_slug: "everyday-life",
    slug: "current-favorites",
    text: {
      "en" => "What songs, books, places, or meals are you currently obsessed with?",
      "es" => "¿Qué canciones, libros, lugares o comidas te tienen obsesionado últimamente?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "everyday-life",
    slug: "home-and-space",
    text: {
      "en" => "What does your home or favorite corner look and feel like today?",
      "es" => "¿Cómo se ve y se siente hoy tu casa o tu rincón favorito?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "everyday-life",
    slug: "current-routine",
    text: {
      "en" => "What daily ritual brings you the most peace right now?",
      "es" => "¿Qué ritual diario te da más paz en esta etapa?"
    },
    position: 5,
    active: true
  },

  # Category: personal-growth
  {
    category_slug: "personal-growth",
    slug: "hardest-lesson",
    text: {
      "en" => "What is the most important lesson you've learned recently?",
      "es" => "¿Cuál es la lección más importante que has aprendido recientemente?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "personal-growth",
    slug: "current-challenge",
    text: {
      "en" => "What challenge are you working through right now, and what is it teaching you?",
      "es" => "¿Qué desafío estás atravesando ahora mismo y qué te está enseñando?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "personal-growth",
    slug: "fear-to-outgrow",
    text: {
      "en" => "What fear or doubt do you hope you will have outgrown by the time you read this?",
      "es" => "¿Qué miedo o duda esperas haber superado cuando leas estas líneas?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "personal-growth",
    slug: "proud-of-overcoming",
    text: {
      "en" => "What have you overcome lately that once felt impossible?",
      "es" => "¿Qué has logrado superar últimamente que antes parecía imposible?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "personal-growth",
    slug: "letting-go",
    text: {
      "en" => "What old habit or expectation are you finally ready to let go of?",
      "es" => "¿Qué viejo hábito o expectativa estás finalmente listo para soltar?"
    },
    position: 5,
    active: true
  },

  # Category: gratitude
  {
    category_slug: "gratitude",
    slug: "moment-never-forget",
    text: {
      "en" => "What moment do you never want to forget?",
      "es" => "¿Qué momento no quieres olvidar nunca?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "gratitude",
    slug: "quiet-blessing",
    text: {
      "en" => "What quiet, ordinary part of your life are you deeply grateful for today?",
      "es" => "¿Por qué parte sencilla y silenciosa de tu vida sientes más gratitud hoy?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "gratitude",
    slug: "unexpected-kindness",
    text: {
      "en" => "What unexpected kindness has meant a lot to you recently?",
      "es" => "¿Qué gesto inesperado de amabilidad significó mucho para ti últimamente?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "gratitude",
    slug: "past-self-thank-you",
    text: {
      "en" => "What would you thank your past self for doing?",
      "es" => "¿Qué le agradecerías a tu yo del pasado por haber hecho?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "gratitude",
    slug: "simple-joy",
    text: {
      "en" => "What happened this week that made you pause and feel thankful?",
      "es" => "¿Qué pasó esta semana que te hizo detenerte y sentir agradecimiento?"
    },
    position: 5,
    active: true
  },

  # Category: predictions
  {
    category_slug: "predictions",
    slug: "where-living",
    text: {
      "en" => "Where do you picture yourself living and spending your mornings?",
      "es" => "¿Dónde te imaginas viviendo y pasando tus mañanas?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "predictions",
    slug: "biggest-surprise",
    text: {
      "en" => "What do you think will surprise you most when you open this letter?",
      "es" => "¿Qué crees que te sorprenderá más cuando abras esta carta?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "predictions",
    slug: "work-and-purpose",
    text: {
      "en" => "What kind of work or projects do you think you'll be pouring your energy into?",
      "es" => "¿En qué tipo de trabajo o proyectos crees que estarás poniendo tu energía?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "predictions",
    slug: "worries-that-fade",
    text: {
      "en" => "Which of today's worries do you predict will feel small by then?",
      "es" => "¿Cuál de tus preocupaciones actuales crees que se verá pequeña para entonces?"
    },
    position: 4,
    active: true
  },
  {
    category_slug: "predictions",
    slug: "world-around-you",
    text: {
      "en" => "What do you think will have changed most in your life—and what will stay the same?",
      "es" => "¿Qué crees que habrá cambiado más en tu vida y qué seguirá igual?"
    },
    position: 5,
    active: true
  },

  # Category: just-because
  {
    category_slug: "just-because",
    slug: "right-now-snapshot",
    text: {
      "en" => "Stop and look around—what do you see, hear, and feel in this exact moment?",
      "es" => "Detente y mira a tu alrededor: ¿qué ves, escuchas y sientes en este preciso instante?"
    },
    position: 1,
    active: true
  },
  {
    category_slug: "just-because",
    slug: "honest-check-in",
    text: {
      "en" => "If you didn't have to filter a single thought, how are you really doing today?",
      "es" => "Si no tuvieras que filtrar ni un solo pensamiento, ¿cómo estás realmente hoy?"
    },
    position: 2,
    active: true
  },
  {
    category_slug: "just-because",
    slug: "weirdly-specific",
    text: {
      "en" => "What oddly specific memory or inside joke do you want to preserve for later?",
      "es" => "¿Qué recuerdo muy específico o chiste interno quieres guardar para después?"
    },
    position: 3,
    active: true
  },
  {
    category_slug: "just-because",
    slug: "letter-without-plan",
    text: {
      "en" => "Start with the first sentence that comes to mind and see where it takes you.",
      "es" => "Empieza con la primera frase que se te venga a la cabeza y deja que te guíe."
    },
    position: 4,
    active: true
  },
  {
    category_slug: "just-because",
    slug: "question-for-future",
    text: {
      "en" => "What is one question you're dying to ask your future self?",
      "es" => "¿Cuál es la pregunta que más ganas tienes de hacerle a tu yo del futuro?"
    },
    position: 5,
    active: true
  }
]

inspirations_data.each do |item|
  category = categories.fetch(item[:category_slug])
  record = Inspiration.find_or_initialize_by(slug: item[:slug])
  record.update!(
    inspiration_category: category,
    text: item[:text],
    position: item[:position],
    active: item[:active]
  )
end

puts "Seeded #{InspirationCategory.count} inspiration categories and #{Inspiration.count} inspirations."
