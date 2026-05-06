OPTION IMPORT;
USE NS johnethel DB lessons;

-- ============================================
-- MATHEMATICS
-- ============================================

CREATE lesson_content:1 CONTENT {
  topic_title: "Introduction to Algebra",
  subject: "Mathematics",
  term: "Term 1",
  week: 1,
  introduction: "Algebra is a branch of mathematics dealing with symbols and the rules for manipulating those symbols. In this lesson, we will explore the fundamental concepts that form the foundation of algebraic thinking.",
  content_sections: [
    { header: "What is a Variable?", body: "A variable is a symbol (usually a letter like x, y, or z) that represents an unknown value or a quantity that can change. Think of it as a placeholder for a number.", sub_points: ["Variables allow us to write general rules and formulas", "Common variables: x, y, z, a, b, c", "A variable can represent any number"]},
    { header: "Algebraic Expressions", body: "An expression is a combination of variables, numbers, and operations (like +, -, ×, ÷). For example: 3x + 5, 2y - 7, or a² + b².", sub_points: ["Terms are separated by + or - signs", "Coefficients are the numbers multiplying variables", "Constants are numbers without variables"]},
    { header: "Evaluating Expressions", body: "To evaluate an expression, substitute the given value for the variable and then calculate. For example, if x = 4, then 3x + 5 = 3(4) + 5 = 12 + 5 = 17.", sub_points: ["Replace each variable with its value", "Follow the order of operations (BODMAS/PEMDAS)", "Double-check your arithmetic"]},
    { header: "Real-World Applications", body: "Algebra is used everywhere: calculating costs, predicting trends, designing buildings, and programming computers. Understanding variables is the first step to solving real problems.", sub_points: ["Shopping: Total cost = price × quantity", "Distance: Distance = speed × time", "Geometry: Area of rectangle = length × width"]}
  ],
  key_points: ["Variables represent unknown or changing values", "Expressions combine variables, numbers, and operations", "Substituting values lets us evaluate expressions", "Algebra has countless real-world applications"],
  conclusion: "You have learned the basics of variables and expressions. Practice substituting different values and simplifying expressions. Next week, we will learn how to solve equations.",
  materials: ["Textbook Chapter 1: Pages 1-15", "Worksheet A: Variable Practice", "Algebra tiles (physical or digital)", "Calculator"],
  objectives: ["Understand what a variable represents", "Identify terms, coefficients, and constants in expressions", "Evaluate simple algebraic expressions by substitution", "Recognize real-world uses of algebra"],
  duration_mins: 45,
  teacher_tips: "Use concrete examples like 'If apples cost $2 each, the total cost is 2 × a where a = number of apples'. Have students create expressions for their own scenarios.",
  formative_assessment: "Exit ticket: Write an expression for 'the total cost of 3 pens and 2 notebooks where p = pen price and n = notebook price'. Evaluate when p = $1.50 and n = $3.",
  summative_assessment: "Quiz: 5 expressions to evaluate, 2 word problems requiring expression writing, 1 real-world application question.",
  remediation: "For struggling students: Use manipulatives (algebra tiles) to represent variables and constants physically. Practice with very simple expressions first (x + 2, 3x).",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Mental math challenge - calculate 3 × 4 + 5, 2 × 7 - 3", teacher_actions: "Lead counting exercise, call on students for answers", assessment: "Observe participation and speed of responses" },
    { step: 2, activity: "Introduction: Present the apple pricing scenario. Ask students to calculate cost for 5, 10, 20 apples.", teacher_actions: "Write expressions on board, guide discovery of variable concept", assessment: "Ask students to explain why '2 × a' works for any number of apples" },
    { step: 3, activity: "Guided practice: Evaluate expressions as a class with x = 3, y = 5", teacher_actions: "Work through 3 examples on board, then have pairs solve 3 more", assessment: "Circulate and check pair work, identify common errors" },
    { step: 4, activity: "Independent practice: Worksheet A - 10 evaluation problems", teacher_actions: "Monitor progress, provide one-on-one help to struggling students", assessment: "Collect worksheets for review" },
    { step: 5, activity: "Real-world connections: Students write expressions for 3 personal scenarios (allowance, sports scores, cooking)", teacher_actions: "Facilitate sharing, provide feedback on expressions", assessment: "Check that expressions correctly represent scenarios" },
    { step: 6, activity: "Closure: Exit ticket + preview next lesson on solving equations", teacher_actions: "Distribute exit tickets, answer questions", assessment: "Review exit tickets to plan differentiation for next lesson" }
  ]
};

CREATE lesson_content:2 CONTENT {
  topic_title: "Solving Linear Equations",
  subject: "Mathematics",
  term: "Term 1",
  week: 2,
  introduction: "A linear equation is an equation that forms a straight line when graphed. Solving equations is one of the most powerful skills in algebra because it allows us to find unknown values. Today we will master the balance method.",
  content_sections: [
    { header: "The Balance Method", body: "Think of an equation as a balance scale. What you do to one side, you must do to the other to keep it balanced. The goal is to isolate the variable on one side.", sub_points: ["Addition undoes subtraction (and vice versa)", "Multiplication undoes division (and vice versa)", "Always perform the same operation on both sides"]},
    { header: "One-Step Equations", body: "These require only one operation to solve. Examples: x + 5 = 12 (subtract 5 from both sides), 3x = 15 (divide both sides by 3).", sub_points: ["Identify the operation being performed on the variable", "Apply the inverse operation to both sides", "Verify by substituting the answer back into the original equation"]},
    { header: "Two-Step Equations", body: "These require two operations. First undo addition/subtraction, then undo multiplication/division. Example: 2x + 3 = 11. Step 1: Subtract 3 → 2x = 8. Step 2: Divide by 2 → x = 4.", sub_points: ["Work in reverse order of operations", "Simplify each step before moving to the next", "Check your answer by substitution"]},
    { header: "Common Mistakes", body: "Students often forget to apply operations to both sides, make sign errors, or skip the verification step. Being aware of these helps prevent them.", sub_points: ["Forgetting to change signs when moving terms", "Dividing before subtracting in two-step equations", "Not checking answers - always verify!"]}
  ],
  key_points: ["Equations must remain balanced - same operation on both sides", "Use inverse operations to isolate the variable", "One-step: single inverse operation", "Two-step: reverse order of operations", "Always verify by substituting the solution"],
  conclusion: "You can now solve one-step and two-step linear equations. Remember the balance method and always check your answers. Next week, we tackle equations with variables on both sides.",
  materials: ["Textbook Chapter 2: Pages 16-32", "Worksheet B: Equation Solving", "Balance scale diagram poster", "Calculator", "Whiteboard markers"],
  objectives: ["Solve one-step linear equations using inverse operations", "Solve two-step linear equations by reversing order of operations", "Verify solutions by substitution", "Identify and avoid common solving errors"],
  duration_mins: 50,
  teacher_tips: "Emphasize checking answers by substitution. Have students say 'Does 4 + 5 = 9? Yes!' aloud. Use balance scale visuals for kinesthetic learners.",
  formative_assessment: "Exit ticket: Solve 3x + 7 = 22 and verify by substitution. Show all steps.",
  summative_assessment: "End-of-week quiz: 8 equations (4 one-step, 4 two-step), must show work and verify 2 answers.",
  remediation: "For students who struggle: Start with very simple one-step equations (x + 1 = 3). Use colored counters to represent positive and negative numbers. Practice isolating variables before combining with numbers.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Quick review - evaluate 2x + 5 when x = 3, 4, 5", teacher_actions: "Call on students rapidly, reinforce substitution concept", assessment: "Check that all students can substitute correctly" },
    { step: 2, activity: "Direct instruction: Balance method concept using physical balance scale or animation", teacher_actions: "Demonstrate with concrete example: x + 3 = 7. Remove 3 from both sides.", assessment: "Ask students to predict what happens if we only remove from one side" },
    { step: 3, activity: "Guided practice: 5 one-step equations as a class", teacher_actions: "Have students come to board to solve, class checks each step", assessment: "Observe confidence levels, identify who needs extra support" },
    { step: 4, activity: "Two-step equations introduction: Work through 2x + 4 = 10 step by step", teacher_actions: "Color-code steps: red for subtraction, blue for division", assessment: "Have students solve 2 more in pairs before independent work" },
    { step: 5, activity: "Independent practice: Worksheet B (mixed one-step and two-step)", teacher_actions: "Circulate, answer questions, pull small group for remediation if needed", assessment: "Collect and review - look for common errors to address tomorrow" },
    { step: 6, activity: "Closure: Common mistakes discussion + exit ticket", teacher_actions: "Share 2-3 anonymous incorrect solutions for class to identify errors", assessment: "Exit tickets inform next lesson grouping" }
  ]
};

CREATE lesson_content:4 CONTENT {
  topic_title: "Quadratic Equations and Factoring",
  subject: "Mathematics",
  term: "Term 1",
  week: 3,
  introduction: "Quadratic equations are equations where the highest power of the variable is 2. They appear everywhere in physics, engineering, and economics. Understanding how to factor quadratics opens the door to solving many real-world problems.",
  content_sections: [
    { header: "What is a Quadratic?", body: "A quadratic equation has the form ax² + bx + c = 0, where a ≠ 0. The graph is a parabola. Examples: x² - 5x + 6 = 0, 2x² + 3x - 2 = 0.", sub_points: ["The highest power is always 2", "Can have 0, 1, or 2 real solutions", "Graphs as a U-shaped curve (parabola)"]},
    { header: "Factoring Simple Quadratics", body: "When a = 1, we look for two numbers that multiply to c and add to b. For x² - 5x + 6 = 0, we need numbers that multiply to 6 and add to -5: -2 and -3. So: (x - 2)(x - 3) = 0.", sub_points: ["Find factor pairs of the constant term (c)", "Check which pair adds to the middle coefficient (b)", "Write as (x + m)(x + n) = 0"]},
    { header: "The Zero Product Property", body: "If A × B = 0, then A = 0 or B = 0 (or both). This is the key to solving factored equations. From (x - 2)(x - 3) = 0, we get x = 2 or x = 3.", sub_points: ["Set each factor equal to zero", "Solve the resulting linear equations", "The solutions are called roots or zeros"]},
    { header: "Checking Your Answers", body: "Always substitute your solutions back into the original equation to verify. This catches sign errors and calculation mistakes before they become habits.", sub_points: ["Plug each solution into ax² + bx + c", "Verify the left side equals zero", "If not, re-check your factoring"]},
    { header: "Real-World Applications", body: "Quadratics model projectile motion (balls, rockets), profit maximization, area problems, and bridge design. The ability to solve them quickly is essential in STEM fields.", sub_points: ["Projectile: h = -16t² + vt + h₀", "Area: A = length × width (often quadratic)", "Profit: P = -ax² + bx + c (parabola opens down)"]}
  ],
  key_points: ["Quadratics have form ax² + bx + c = 0", "Factoring: find two numbers that multiply to c and add to b", "Zero product property: if product is zero, a factor is zero", "Always verify solutions by substitution", "Quadratics model many real-world phenomena"],
  conclusion: "You now know how to factor simple quadratics and apply the zero product property. Practice with different signs (positive/negative c and b). Next week, we will explore the quadratic formula for equations that don't factor nicely.",
  materials: ["Textbook Chapter 3: Pages 33-50", "Factoring practice worksheet", "Graphing calculator or Desmos", "Factor pair reference card", "Parabola graph paper"],
  objectives: ["Identify quadratic equations and their components", "Factor simple quadratics (a = 1)", "Apply the zero product property to find solutions", "Verify solutions by substitution", "Connect quadratics to real-world contexts"],
  duration_mins: 55,
  teacher_tips: "Create a 'factor pair hunt' game. Give students the constant term and have them race to find all factor pairs. Use Desmos to show how the parabola crosses the x-axis at the solutions.",
  formative_assessment: "Quick check: Factor and solve x² + 7x + 12 = 0. Show factor pairs, factored form, and solutions.",
  summative_assessment: "Quiz: 6 factoring problems (mixed signs), 2 word problems requiring setting up and solving quadratics, 1 graphing question.",
  remediation: "For struggling students: Focus only on positive c and b first. Use area model diagrams (rectangles with sides representing factors). Practice finding factor pairs of numbers 1-30 until automatic.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Factor pairs race - list all factor pairs of 12, 18, 24, 36", teacher_actions: "Time the activity, celebrate speed and accuracy", assessment: "Check who struggles with negative factor pairs" },
    { step: 2, activity: "Introduction: Show parabola graph, identify x-intercepts. Connect to factoring.", teacher_actions: "Use Desmos or graphing calculator for live demonstration", assessment: "Ask students to predict x-intercepts from factored form" },
    { step: 3, activity: "Direct instruction: Step-by-step factoring of x² - 5x + 6", teacher_actions: "Think aloud, show all factor pairs, identify correct pair", assessment: "Have students solve x² + 5x + 6 independently, check together" },
    { step: 4, activity: "Guided practice: 6 problems with mixed signs (positive/negative c and b)", teacher_actions: "Have students work in pairs, circulate for misconceptions", assessment: "Identify common sign errors to address" },
    { step: 5, activity: "Application: Projectile problem - ball thrown upward, when does it hit ground?", teacher_actions: "Set up equation together, have students solve", assessment: "Check that students can extract quadratic from word problem" },
    { step: 6, activity: "Closure: Exit ticket + preview quadratic formula", teacher_actions: "Distribute tickets, show a non-factorable quadratic to motivate next lesson", assessment: "Review tickets, plan differentiation" }
  ]
};

-- ============================================
-- SCIENCE
-- ============================================

CREATE lesson_content:3 CONTENT {
  topic_title: "The Water Cycle",
  subject: "Science",
  term: "Term 1",
  week: 1,
  introduction: "The water cycle describes how water moves through Earth's systems. Water is essential for all life, and understanding how it circulates through our planet helps us appreciate why conserving water matters.",
  content_sections: [
    { header: "Evaporation", body: "Evaporation is the process where liquid water turns into water vapor (gas) due to heat from the sun. This happens from oceans, lakes, rivers, and even soil. The warmer it is, the faster evaporation occurs.", sub_points: ["Heat energy breaks bonds between water molecules", "Oceans provide about 90% of atmospheric water vapor", "Evaporation is a cooling process for the surface"]},
    { header: "Condensation", body: "As water vapor rises into cooler parts of the atmosphere, it cools down and changes back into liquid droplets, forming clouds. This is condensation - the opposite of evaporation.", sub_points: ["Cooler temperatures slow down water molecules", "Dust particles help water droplets form", "Clouds are collections of tiny water droplets or ice crystals"]},
    { header: "Precipitation", body: "When cloud droplets combine and grow heavy enough, they fall back to Earth as precipitation. This can be rain, snow, sleet, or hail depending on temperature.", sub_points: ["Rain forms when temperatures are above freezing", "Snow forms when temperatures are below freezing", "Hail forms in strong thunderstorms with updrafts"]},
    { header: "Collection and Runoff", body: "Water that falls on land collects in rivers, lakes, and oceans. Some seeps into the ground (groundwater), and some flows across the surface (runoff). This water will eventually evaporate again, completing the cycle.", sub_points: ["Rivers carry water back to oceans", "Groundwater feeds springs and wells", "The cycle has no beginning or end - it's continuous"]},
    { header: "Human Impact", body: "Human activities affect the water cycle. Deforestation reduces transpiration, pollution contaminates water sources, and climate change alters precipitation patterns. Understanding the cycle helps us make better environmental decisions.", sub_points: ["Deforestation reduces local rainfall", "Pollution affects water quality at every stage", "Climate change intensifies droughts and floods"]}
  ],
  key_points: ["Evaporation: liquid water → water vapor (heat)", "Condensation: water vapor → liquid droplets (cooling)", "Precipitation: water falls as rain, snow, sleet, or hail", "Collection: water gathers in rivers, lakes, oceans, groundwater", "The water cycle is continuous and essential for life", "Human activities impact the water cycle significantly"],
  conclusion: "You now understand the four main stages of the water cycle. Draw the complete cycle and label each stage with arrows showing the direction of water movement. Think about how your daily water use fits into this global cycle.",
  materials: ["Water cycle diagram poster", "Glass jar, hot water, and ice cube (condensation demo)", "Video: BBC Earth water cycle documentary (5 min clip)", "Blank diagram worksheet", "Colored pencils", "Kettle (for evaporation demonstration)"],
  objectives: ["Name and explain the four main stages of the water cycle", "Describe the conditions needed for evaporation and condensation", "Identify different forms of precipitation and when they occur", "Explain how collection and runoff complete the cycle", "Discuss human impacts on the water cycle"],
  duration_mins: 50,
  teacher_tips: "Use a kettle to demonstrate evaporation - students can see the steam. Place a cold metal spoon above it to show condensation. The jar demo works well too: hot water in jar, ice on lid = condensation on lid.",
  formative_assessment: "Label a blank water cycle diagram with arrows and descriptions for each stage. Include one human impact annotation.",
  summative_assessment: "Written test: Match terms to definitions, label a diagram, short answer on human impacts, predict what happens if one stage is disrupted.",
  remediation: "For struggling students: Watch the video again in small groups. Use physical models (blue beads for water, move them between labeled containers). Create a simple 4-step flowchart before attempting the full diagram.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Where does rain come from? Brainstorm in pairs, share ideas.", teacher_actions: "Record ideas on board without correcting, use as baseline for learning", assessment: "Identify misconceptions (e.g., 'rain comes from clouds' without understanding how clouds form)" },
    { step: 2, activity: "Demonstration: Kettle evaporation + cold spoon condensation", teacher_actions: "Explain what students are seeing, connect to scientific terms", assessment: "Ask students to explain what happened using the terms evaporation and condensation" },
    { step: 3, activity: "Video: BBC Earth water cycle clip (5 minutes)", teacher_actions: "Pause at key moments to check understanding, ask prediction questions", assessment: "Have students take notes on the 4 main stages" },
    { step: 4, activity: "Guided diagram: Label water cycle diagram together as a class", teacher_actions: "Project blank diagram, have students come up to label parts", assessment: "Check that arrows show correct direction of water movement" },
    { step: 5, activity: "Independent work: Complete detailed diagram with descriptions + human impact section", teacher_actions: "Circulate, provide feedback, pull small group for extra support", assessment: "Collect diagrams to assess understanding of all stages" },
    { step: 6, activity: "Closure: Think-pair-share - 'How would the water cycle change if Earth had no oceans?'", teacher_actions: "Facilitate discussion, summarize key points", assessment: "Listen for understanding of interdependence between stages" }
  ]
};

CREATE lesson_content:5 CONTENT {
  topic_title: "Photosynthesis and Plant Structure",
  subject: "Science",
  term: "Term 1",
  week: 2,
  introduction: "Photosynthesis is the process by which plants convert light energy into chemical energy (sugar). This process is the foundation of almost all life on Earth because it produces the oxygen we breathe and the food that supports entire ecosystems.",
  content_sections: [
    { header: "The Photosynthesis Equation", body: "6CO₂ + 6H₂O + light energy → C₆H₁₂O₆ + 6O₂. In words: carbon dioxide + water + light → glucose + oxygen. Plants take in CO₂ and water, use sunlight to power the reaction, and produce sugar and oxygen.", sub_points: ["Carbon dioxide enters through stomata (leaf pores)", "Water is absorbed by roots and transported up the stem", "Chlorophyll in chloroplasts captures light energy", "Glucose is used for energy or stored as starch", "Oxygen is released as a byproduct"]},
    { header: "Plant Structure for Photosynthesis", body: "Leaves are the primary photosynthetic organs. They are flat and thin to maximize light capture. The waxy cuticle prevents water loss, while stomata allow gas exchange.", sub_points: ["Epidermis: protective outer layer", "Palisade mesophyll: tightly packed cells with many chloroplasts", "Spongy mesophyll: air spaces for gas circulation", "Xylem: transports water from roots", "Phloem: transports sugars to other parts of plant"]},
    { header: "Factors Affecting Photosynthesis", body: "Three main factors limit the rate: light intensity, carbon dioxide concentration, and temperature. Each has an optimal range - too much or too little reduces the rate.", sub_points: ["Light: more light = faster photosynthesis (up to a point)", "CO₂: increasing CO₂ increases rate (up to saturation)", "Temperature: enzymes work best around 25-30°C; too hot denatures them", "Water: shortage closes stomata, reducing CO₂ intake"]},
    { header: "Why Photosynthesis Matters", body: "Without photosynthesis, there would be no oxygen to breathe, no food for herbivores, and no energy flowing through ecosystems. Fossil fuels (coal, oil, gas) are ancient photosynthetic products.", sub_points: ["Produces ~90% of Earth's oxygen", "Base of nearly all food chains", "Removes CO₂ from atmosphere (carbon sink)", "Source of wood, cotton, and many medicines"]}
  ],
  key_points: ["Photosynthesis converts light energy into chemical energy (glucose)", "Equation: CO₂ + H₂O + light → glucose + O₂", "Occurs mainly in leaves, specifically chloroplasts", "Three limiting factors: light, CO₂, temperature", "Essential for oxygen production and food chains", "Plant structure is adapted for efficient photosynthesis"],
  conclusion: "Photosynthesis is the most important biological process on Earth. You can now explain the equation, identify the structures involved, and discuss the factors that affect the rate. Consider: what would happen if photosynthesis stopped for just one day?",
  materials: ["Microscope and prepared leaf cross-section slides", "Elodea (water plant) for photosynthesis demonstration", "Bromothymol blue indicator (CO₂ detection)", "Plant structure diagram", "Photosynthesis equation poster", "Light meter (optional)"],
  objectives: ["Write and explain the photosynthesis equation", "Identify and describe structures involved in photosynthesis", "Explain how light, CO₂, and temperature affect the rate", "Describe the importance of photosynthesis for life on Earth", "Observe photosynthesis under a microscope"],
  duration_mins: 55,
  teacher_tips: "The bromothymol blue demo is powerful: blue water + elodea in light turns yellow (CO₂ used), stays blue in dark. Use real leaf cross-sections under microscopes - students love seeing stomata.",
  formative_assessment: "Label a leaf cross-section diagram and explain the function of palisade mesophyll, spongy mesophyll, xylem, and phloem.",
  summative_assessment: "Test: Write the photosynthesis equation from memory, label a plant structure diagram, explain how each limiting factor affects rate, predict outcome of an experiment.",
  remediation: "For struggling students: Use color-coded flashcards for the equation components. Watch time-lapse videos of plants growing toward light. Simplify limiting factors to 'more light = more food' initially.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: 'What do plants eat?' Brainstorm, then introduce photosynthesis as 'making their own food'", teacher_actions: "Address common misconceptions (plants don't eat soil!)", assessment: "Check prior knowledge about plant nutrition" },
    { step: 2, activity: "Direct instruction: Photosynthesis equation with color-coded components", teacher_actions: "Use large visual equation, have students copy into notes with colors", assessment: "Ask students to identify what plants take in vs. what they produce" },
    { step: 3, activity: "Microscope lab: Examine leaf cross-sections, identify palisade and spongy mesophyll", teacher_actions: "Demonstrate proper microscope use, provide guided worksheet", assessment: "Check labeled diagrams for accuracy" },
    { step: 4, activity: "Demonstration: Bromothymol blue + elodea in light vs. dark", teacher_actions: "Set up at start of lesson, observe color change during class", assessment: "Have students predict and explain the color change" },
    { step: 5, activity: "Graph analysis: Interpret graphs showing light intensity vs. photosynthesis rate", teacher_actions: "Guide students through reading axes, identifying trends, explaining plateaus", assessment: "Have students sketch predicted graphs for CO₂ and temperature" },
    { step: 6, activity: "Closure: Exit ticket - write equation + explain one limiting factor + one real-world consequence if photosynthesis stopped", teacher_actions: "Collect tickets, preview cellular respiration (opposite process)", assessment: "Tickets inform next lesson grouping" }
  ]
};

CREATE lesson_content:6 CONTENT {
  topic_title: "Forces and Motion",
  subject: "Science",
  term: "Term 1",
  week: 3,
  introduction: "Forces are pushes or pulls that cause objects to move, stop, or change direction. Understanding forces and motion is essential for everything from sports to space travel. Newton's three laws of motion form the foundation of classical mechanics.",
  content_sections: [
    { header: "Newton's First Law (Inertia)", body: "An object at rest stays at rest, and an object in motion stays in motion at constant velocity, unless acted upon by an unbalanced force. This property of resisting change in motion is called inertia.", sub_points: ["Inertia depends on mass - more mass = more inertia", "Seatbelts prevent injury by overcoming inertia during sudden stops", "Spacecraft coast forever in space because there's no friction"]},
    { header: "Newton's Second Law (F = ma)", body: "The acceleration of an object is directly proportional to the net force acting on it and inversely proportional to its mass. F = ma. If you push harder, it accelerates more. If it's heavier, it accelerates less.", sub_points: ["Force (F) measured in Newtons (N)", "Mass (m) measured in kilograms (kg)", "Acceleration (a) measured in m/s²", "Double the force = double the acceleration", "Double the mass = half the acceleration"]},
    { header: "Newton's Third Law (Action-Reaction)", body: "For every action, there is an equal and opposite reaction. When you push on a wall, the wall pushes back on you with equal force. This is why rockets work - they push exhaust down, exhaust pushes rocket up.", sub_points: ["Forces always come in pairs", "The two forces act on different objects", "Action and reaction forces are equal in magnitude but opposite in direction"]},
    { header: "Types of Forces", body: "Forces can be contact forces (friction, tension, normal force) or non-contact forces (gravity, magnetism, electrostatic). Understanding which forces act on an object helps predict its motion.", sub_points: ["Gravity: pulls objects toward Earth (9.8 m/s²)", "Friction: opposes motion between surfaces", "Normal force: surface pushes back perpendicular to contact", "Tension: force through ropes, strings, cables"]},
    { header: "Calculating Net Force", body: "When multiple forces act on an object, find the net force by adding forces in the same direction and subtracting forces in opposite directions. The direction of net force determines the direction of acceleration.", sub_points: ["Forces in same direction: add them", "Forces in opposite directions: subtract them", "Net force = 0 means constant velocity (or rest)", "Net force ≠ 0 means acceleration in direction of net force"]}
  ],
  key_points: ["First Law: Objects resist changes in motion (inertia)", "Second Law: F = ma - force causes acceleration", "Third Law: Every action has an equal and opposite reaction", "Forces can be contact or non-contact", "Net force determines acceleration direction and magnitude", "Understanding forces explains real-world motion"],
  conclusion: "Newton's laws explain virtually all everyday motion. You can now calculate forces, predict acceleration, and understand why objects move the way they do. Apply these laws to analyze sports, vehicles, and space exploration.",
  materials: ["Dynamics carts and track", "Spring scales (5N and 10N)", "Mass sets (100g, 200g, 500g)", "Newton's laws demonstration kit", "Force diagram worksheets", "Video: Apollo rocket launch (action-reaction)", "Friction blocks with different surfaces"],
  objectives: ["State and explain Newton's three laws of motion", "Calculate net force and acceleration using F = ma", "Identify action-reaction force pairs", "Distinguish between contact and non-contact forces", "Draw force diagrams for simple situations", "Apply Newton's laws to real-world scenarios"],
  duration_mins: 60,
  teacher_tips: "Use dynamics carts for F=ma verification. Have students predict which cart (heavy vs. light) wins a race when pushed with equal force. The Apollo launch video powerfully demonstrates action-reaction.",
  formative_assessment: "Draw a force diagram for a book resting on a table. Identify all forces, their directions, and whether they are contact or non-contact. Calculate net force.",
  summative_assessment: "Test: State all three laws, solve 4 F=ma problems, identify action-reaction pairs in 3 scenarios, draw force diagrams, explain a real-world application.",
  remediation: "For struggling students: Focus on qualitative understanding first (what happens, not calculations). Use virtual simulations (PhET). Practice identifying forces before calculating. Use very simple numbers (F=10N, m=2kg → a=5m/s²).",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Push a dynamics cart gently, then hard. Ask: 'What changed? Why did it go faster?'", teacher_actions: "Guide students toward force and acceleration concepts", assessment: "Check prior understanding of force-motion relationship" },
    { step: 2, activity: "First Law demo: Coin on card on cup. Flick card - coin drops into cup.", teacher_actions: "Explain inertia: coin resisted motion, gravity pulled it down", assessment: "Have students explain in their own words why the coin fell straight down" },
    { step: 3, activity: "Second Law lab: Measure acceleration of carts with different masses and forces", teacher_actions: "Demonstrate setup, have groups collect data", assessment: "Check data tables for consistency with F=ma" },
    { step: 4, activity: "Third Law demo: Two students on scooters push apart; balloon rocket", teacher_actions: "Emphasize equal and opposite, different objects", assessment: "Have students identify action-reaction pairs in each demo" },
    { step: 5, activity: "Problem solving: Work through 4 F=ma problems as a class, then independent practice", teacher_actions: "Model problem-solving strategy: draw diagram, identify forces, apply formula, check units", assessment: "Circulate during independent work, provide immediate feedback" },
    { step: 6, activity: "Closure: 'Physics in sports' - analyze forces in basketball shot, soccer kick, swimming", teacher_actions: "Facilitate discussion, connect to student interests", assessment: "Exit ticket: Apply one law to explain a sport of your choice" }
  ]
};

-- ============================================
-- ENGLISH LANGUAGE
-- ============================================

CREATE lesson_content:7 CONTENT {
  topic_title: "Narrative Writing: Building Compelling Characters",
  subject: "English Language",
  term: "Term 1",
  week: 1,
  introduction: "Characters are the heart of any story. Readers remember stories because they care about the people (or animals, or creatures) in them. In this lesson, you will learn how to create characters that feel real, have depth, and drive your narrative forward.",
  content_sections: [
    { header: "What Makes a Character Believable?", body: "Real people have contradictions, flaws, desires, and fears. Believable characters should too. They shouldn't be all good or all bad. Give your characters: a clear motivation (what do they want?), a flaw (what holds them back?), and a secret (what don't they want others to know?).", sub_points: ["Motivation drives every action the character takes", "Flaws create conflict and make characters relatable", "Secrets add tension and reader engagement", "Contradictions make characters feel human"]},
    { header: "Character Types: Flat vs. Round", body: "Flat characters have one or two traits and don't change. Round characters are complex, multi-dimensional, and often transform throughout the story. Most protagonists should be round characters.", sub_points: ["Flat characters: the grumpy neighbor, the loyal friend", "Round characters: change, grow, have internal conflicts", "Static characters don't change; dynamic characters do", "Both types have roles - flat for minor, round for major"]},
    { header: "Showing vs. Telling", body: "Don't tell readers your character is brave - show them through actions, dialogue, and thoughts. Instead of 'John was brave,' write 'John stepped between the bully and his friend, even though his hands were shaking.'", sub_points: ["Show through action: what the character does", "Show through dialogue: what they say and how they say it", "Show through thoughts: their internal monologue", "Show through others' reactions: how people respond to them"]},
    { header: "Creating Character Profiles", body: "Before writing, create a detailed profile for main characters. Include: physical appearance, background, personality traits, strengths, weaknesses, goals, fears, and relationships with other characters.", sub_points: ["Physical: age, height, distinguishing features, clothing style", "Background: family, education, past experiences, culture", "Personality: introvert/extrovert, optimistic/pessimistic, habits", "Relationships: who do they love, hate, fear, trust?"]}
  ],
  key_points: ["Believable characters have motivations, flaws, and secrets", "Round characters are complex and often change; flat characters are simple and static", "Show character traits through action, dialogue, and thoughts, not just description", "Character profiles help maintain consistency and depth", "Characters should drive the plot, not just react to it"],
  conclusion: "You now have tools to create characters that readers will remember. Start building profiles for your main characters before you write. Remember: the best characters are the ones who surprise us while still feeling true to themselves.",
  materials: ["Character profile template worksheet", "Excerpts from 'Charlotte's Web', 'Harry Potter', 'The Giver'", "Character trait word bank", "Peer review checklist", "Sample character profiles (good and bad examples)"],
  objectives: ["Identify what makes characters believable and engaging", "Distinguish between flat and round characters", "Apply 'show, don't tell' techniques to character development", "Create detailed character profiles for narrative writing", "Analyze character development in published texts"],
  duration_mins: 50,
  teacher_tips: "Have students analyze a character from a book they love using the profile template. Then have them create a profile for a character in their own story. Share and provide peer feedback.",
  formative_assessment: "Character profile completion: Create a full profile for a protagonist including motivation, flaw, secret, and relationships.",
  summative_assessment: "Write a 500-word scene introducing your main character. Show (don't tell) at least 3 traits through action and dialogue.",
  remediation: "For struggling students: Start with a character based on themselves or someone they know well. Use sentence starters: 'My character wants...', 'My character is afraid of...', 'My character always...'",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Describe a famous character in 3 words. Partner guesses who it is.", teacher_actions: "Discuss what made descriptions effective (specific traits, not generic)", assessment: "Check understanding of character traits vs. physical description" },
    { step: 2, activity: "Mini-lesson: Flat vs. round characters using excerpts from familiar texts", teacher_actions: "Read excerpts aloud, have students identify character type and evidence", assessment: "Check comprehension with thumbs up/down for flat/round identification" },
    { step: 3, activity: "Guided practice: Rewrite 'telling' sentences into 'showing' paragraphs", teacher_actions: "Model 2 examples, then have pairs rewrite 3 sentences", assessment: "Share rewrites, identify strongest showing techniques" },
    { step: 4, activity: "Independent work: Complete character profile template for story protagonist", teacher_actions: "Circulate, ask probing questions to deepen thinking", assessment: "Check that profiles include motivation, flaw, and secret" },
    { step: 5, activity: "Peer review: Exchange profiles with partner, provide feedback using checklist", teacher_actions: "Model constructive feedback using 'I like... I wonder...' format", assessment: "Review feedback quality, address common gaps" },
    { step: 6, activity: "Closure: Share one character detail you're most proud of. Exit ticket: What makes your character interesting?", teacher_actions: "Celebrate creativity, preview next lesson on plot structure", assessment: "Exit tickets reveal depth of character development" }
  ]
};

CREATE lesson_content:8 CONTENT {
  topic_title: "Figurative Language: Metaphors, Similes, and Personification",
  subject: "English Language",
  term: "Term 1",
  week: 2,
  introduction: "Figurative language transforms ordinary writing into vivid, memorable prose. Instead of saying 'the sun was hot,' you can say 'the sun was an oven baking the earth.' Today we will explore three powerful tools: metaphors, similes, and personification.",
  content_sections: [
    { header: "Similes: Direct Comparison", body: "A simile compares two unlike things using 'like' or 'as.' It makes descriptions concrete and relatable. Example: 'Her smile was as bright as the sun.' The reader instantly pictures warmth and radiance.", sub_points: ["Always uses 'like' or 'as'", "Creates vivid mental images", "Helps readers relate unfamiliar things to familiar ones", "Common in everyday speech and poetry"]},
    { header: "Metaphors: Implied Comparison", body: "A metaphor states that one thing IS another, creating a stronger connection than a simile. Example: 'Time is a thief.' This suggests time steals our moments, our youth, our opportunities - a much deeper meaning than a simile could convey.", sub_points: ["Does NOT use 'like' or 'as'", "Creates deeper, more powerful connections", "Requires readers to think more actively", "Extended metaphors develop a comparison throughout a text"]},
    { header: "Personification: Human Qualities to Non-Human Things", body: "Personification gives human characteristics to animals, objects, or abstract concepts. Example: 'The wind whispered through the trees.' Wind cannot literally whisper, but this makes the scene feel alive and mysterious.", sub_points: ["Brings inanimate objects to life", "Creates emotional connections", "Common in children's literature and poetry", "Can make abstract concepts concrete (e.g., 'Justice is blind')"]},
    { header: "Why Figurative Language Matters", body: "Figurative language does more than decorate writing - it creates emotional impact, deepens meaning, and helps readers experience the text rather than just read it. It turns abstract feelings into concrete images.", sub_points: ["Evokes emotions more powerfully than literal language", "Creates memorable images that stick with readers", "Adds layers of meaning to simple descriptions", "Distinguishes creative writing from plain prose"]},
    { header: "Avoiding Clichés", body: "Clichés are overused comparisons that have lost their impact. 'Busy as a bee,' 'cold as ice,' 'strong as an ox' - readers have heard these so many times they no longer create vivid images. Create fresh, original comparisons.", sub_points: ["Test: Have you heard this comparison before?", "Think of unexpected connections", "Use specific details from your own experience", "Aim to surprise and delight your reader"]}
  ],
  key_points: ["Similes compare using 'like' or 'as'", "Metaphors state one thing IS another (stronger connection)", "Personification gives human qualities to non-human things", "Figurative language creates emotional impact and vivid images", "Avoid clichés - create fresh, original comparisons", "Effective figurative language deepens meaning and engages readers"],
  conclusion: "You can now identify and create similes, metaphors, and personification. Practice transforming literal sentences into figurative ones. Remember: the best figurative language makes readers see, feel, and experience your writing in a new way.",
  materials: ["Figurative language identification worksheet", "Poetry collection with annotated examples", "Cliché bingo cards", "Creative writing prompts with figurative language focus", "Color-coded highlighters (blue=simile, red=metaphor, green=personification)"],
  objectives: ["Identify similes, metaphors, and personification in texts", "Explain the effect of figurative language on the reader", "Create original similes, metaphors, and personification", "Distinguish between effective figurative language and clichés", "Apply figurative language to enhance descriptive writing"],
  duration_mins: 45,
  teacher_tips: "Play 'Cliché Bingo' - students mark off clichés they hear in a week. Then challenge them to rewrite each cliché originally. Use music lyrics - pop songs are full of figurative language students will recognize.",
  formative_assessment: "Transform 5 literal sentences into figurative ones (at least one simile, one metaphor, one personification).",
  summative_assessment: "Write a 300-word descriptive paragraph about a place using at least 3 similes, 2 metaphors, and 2 examples of personification. No clichés allowed.",
  remediation: "For struggling students: Start with similes only (easiest to identify). Use visual aids - show a picture and have students create comparisons. Provide sentence frames: 'The ____ was like a ____,' 'The ____ was a ____.'",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Read a paragraph literal version and figurative version of the same scene. Vote on which is more engaging.", teacher_actions: "Discuss why figurative version creates stronger images", assessment: "Check that students recognize the impact of figurative language" },
    { step: 2, activity: "Direct instruction: Definitions with color-coded examples from poetry", teacher_actions: "Read examples aloud, have students identify type and explain effect", assessment: "Quick check: thumbs up for simile, thumbs down for metaphor, sideways for personification" },
    { step: 3, activity: "Guided practice: Hunt for figurative language in song lyrics (projected)", teacher_actions: "Use popular songs, have students highlight and categorize", assessment: "Check accuracy of identification and categorization" },
    { step: 4, activity: "Cliché transformation: Rewrite 10 clichés into original comparisons", teacher_actions: "Model 2 transformations, then have pairs work on remaining 8", assessment: "Share best rewrites, discuss what makes them effective" },
    { step: 5, activity: "Independent writing: 300-word descriptive paragraph with figurative language requirements", teacher_actions: "Circulate, provide individual feedback on technique", assessment: "Collect for review, identify students who need more support" },
    { step: 6, activity: "Closure: Gallery walk - post paragraphs, read and vote on most vivid image", teacher_actions: "Facilitate positive feedback, celebrate creativity", assessment: "Peer votes reveal which techniques are most effective" }
  ]
};

CREATE lesson_content:9 CONTENT {
  topic_title: "Persuasive Writing: Crafting Arguments That Convince",
  subject: "English Language",
  term: "Term 1",
  week: 3,
  introduction: "Persuasive writing is everywhere: advertisements, speeches, editorials, and even text messages trying to convince a friend. Learning to craft persuasive arguments makes you a more effective communicator and helps you think critically about the arguments others make.",
  content_sections: [
    { header: "The Rhetorical Triangle: Ethos, Pathos, Logos", body: "Aristotle identified three ways to persuade: ethos (credibility), pathos (emotion), and logos (logic). The most persuasive arguments use all three. Ethos convinces readers you are trustworthy. Pathos makes them feel something. Logos provides evidence and reasoning.", sub_points: ["Ethos: credentials, experience, fairness, citing experts", "Pathos: stories, vivid language, appeals to values and fears", "Logos: facts, statistics, examples, logical reasoning", "Effective persuasion balances all three"]},
    { header: "Building a Strong Argument", body: "A persuasive piece needs: a clear claim (what you believe), strong reasons (why you're right), solid evidence (proof for your reasons), and a counterargument (addressing the opposition). This structure makes your case hard to refute.", sub_points: ["Claim: a clear, debatable statement of position", "Reasons: logical explanations supporting the claim", "Evidence: facts, statistics, expert opinions, examples", "Counterargument: acknowledge opposition, then refute it"]},
    { header: "Persuasive Techniques", body: "Beyond the rhetorical triangle, specific techniques strengthen persuasion: repetition (emphasizes key points), rhetorical questions (engage readers), analogies (make complex ideas simple), and appeals to authority (cite experts).", sub_points: ["Repetition: 'We want change. We need change. We demand change.'", "Rhetorical questions: 'What kind of world do we want to leave our children?'", "Analogies: 'A school without books is like a kitchen without food.'", "Appeal to authority: 'According to Dr. Smith, a leading climate scientist...'"]},
    { header: "Avoiding Logical Fallacies", body: "Fallacies are errors in reasoning that weaken arguments. Common ones: ad hominem (attacking the person instead of the argument), false dichotomy (only two options when more exist), and hasty generalization (conclusion from too little evidence).", sub_points: ["Ad hominem: 'You can't trust his opinion because he's young.'", "False dichotomy: 'You're either with us or against us.'", "Hasty generalization: 'I failed math, so math is useless.'", "Bandwagon: 'Everyone is doing it, so it must be right.'"]},
    { header: "The Call to Action", body: "Every persuasive piece should end with a clear call to action - tell readers exactly what you want them to do. Be specific: 'Sign this petition,' 'Write to your representative,' 'Change your daily habits.' Vague endings waste the momentum you built.", sub_points: ["Make it specific and achievable", "Create urgency: 'Act now before it's too late'", "Show the benefit of taking action", "Remove barriers: provide links, addresses, clear steps"]}
  ],
  key_points: ["Ethos (credibility), pathos (emotion), and logos (logic) are the three pillars of persuasion", "Strong arguments have clear claims, reasons, evidence, and counterarguments", "Techniques like repetition, rhetorical questions, and analogies strengthen persuasion", "Avoid logical fallacies that undermine your credibility", "End with a specific, urgent call to action", "Persuasive writing requires both emotional appeal and logical reasoning"],
  conclusion: "You now understand the art and science of persuasion. Whether you're writing an essay, giving a speech, or debating with friends, use ethos to build trust, pathos to connect emotionally, and logos to provide evidence. And always tell your audience what to do next.",
  materials: ["Persuasive essay rubric", "Sample persuasive essays (strong and weak)", "Rhetorical triangle diagram poster", "Logical fallacy flashcards", "Current events articles for practice arguments", "Peer editing checklist for persuasive writing"],
  objectives: ["Identify ethos, pathos, and logos in persuasive texts", "Construct arguments with claims, reasons, evidence, and counterarguments", "Apply persuasive techniques effectively", "Identify and avoid logical fallacies", "Write persuasive pieces with clear calls to action"],
  duration_mins: 55,
  teacher_tips: "Use current events that students care about (school policies, environmental issues, social media). Have them analyze real advertisements for persuasive techniques. Debates are excellent practice - assign positions randomly to force students to argue both sides.",
  formative_assessment: "Analyze a short persuasive text: identify the claim, two reasons, one piece of evidence, and the call to action. Label ethos, pathos, and logos.",
  summative_assessment: "Write a 500-word persuasive essay on a provided topic. Must include: clear claim, 2 reasons with evidence, counterargument, call to action, and at least 2 persuasive techniques.",
  remediation: "For struggling students: Start with oral arguments before writing. Use graphic organizers to plan claims, reasons, and evidence. Practice identifying persuasive techniques in advertisements before creating their own.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Show 3 ads, have students vote on most convincing. Discuss why.", teacher_actions: "Introduce rhetorical triangle concepts using ads as examples", assessment: "Check prior understanding of persuasion" },
    { step: 2, activity: "Direct instruction: Ethos, pathos, logos with video clips of famous speeches", teacher_actions: "Pause clips to identify techniques, have students take notes", assessment: "Quick check: identify which appeal is dominant in each clip" },
    { step: 3, activity: "Guided practice: Analyze a sample persuasive essay using graphic organizer", teacher_actions: "Model analysis, then have pairs complete organizer for second essay", assessment: "Check that students can identify all argument components" },
    { step: 4, activity: "Fallacy hunt: Find logical fallacies in provided arguments (funny examples)", teacher_actions: "Use exaggerated examples to make concepts memorable", assessment: "Have students create their own fallacious argument, then fix it" },
    { step: 5, activity: "Drafting: Write persuasive essay using provided graphic organizer and rubric", teacher_actions: "Circulate, conference with students about their arguments", assessment: "Check drafts for claim clarity and evidence quality" },
    { step: 6, activity: "Closure: Share calls to action. Peer feedback on persuasiveness.", teacher_actions: "Model giving specific, constructive feedback", assessment: "Exit ticket: Rate your own essay's persuasiveness 1-5 and explain why" }
  ]
};

-- ============================================
-- SOCIAL STUDIES
-- ============================================

CREATE lesson_content:10 CONTENT {
  topic_title: "Introduction to Democracy and Citizenship",
  subject: "Social Studies",
  term: "Term 1",
  week: 1,
  introduction: "Democracy comes from Greek words 'demos' (people) and 'kratos' (power). It means 'rule by the people.' Understanding how democracy works, what rights citizens have, and how to participate responsibly is essential for being an informed member of society.",
  content_sections: [
    { header: "What is Democracy?", body: "Democracy is a system of government where citizens exercise power by voting. In a direct democracy, citizens vote on every issue. In a representative democracy (like most modern nations), citizens elect representatives to make decisions on their behalf.", sub_points: ["Direct democracy: citizens vote on laws directly (rare today)", "Representative democracy: elected officials make decisions", "Key principle: government derives power from the consent of the governed", "Free and fair elections are essential"]},
    { header: "Core Democratic Values", body: "Democracy rests on fundamental values: liberty (freedom), equality (equal treatment under law), justice (fairness), and tolerance (respecting differences). These values guide how democratic societies function and treat their citizens.", sub_points: ["Liberty: freedom of speech, religion, assembly, press", "Equality: all citizens have equal rights and opportunities", "Justice: fair laws applied equally, access to courts", "Tolerance: respecting diverse opinions, cultures, beliefs"]},
    { header: "Rights and Responsibilities of Citizens", body: "Citizenship comes with both rights and responsibilities. Rights protect you (freedom of speech, right to vote, fair trial). Responsibilities ensure society functions (voting, obeying laws, jury duty, paying taxes, staying informed).", sub_points: ["Rights: voting, free speech, religious freedom, education, equality", "Responsibilities: voting, obeying laws, paying taxes, jury duty", "Active citizenship: staying informed, volunteering, peaceful protest", "Rights and responsibilities are two sides of the same coin"]},
    { header: "How Government Works", body: "Most democracies separate power into three branches: legislative (makes laws), executive (enforces laws), and judicial (interprets laws). This separation prevents any one person or group from having too much power.", sub_points: ["Legislative branch: parliament, congress, assemblies - create laws", "Executive branch: president, prime minister, cabinet - implement laws", "Judicial branch: courts, judges - interpret laws and resolve disputes", "Checks and balances: each branch can limit the others' power"]},
    { header: "Participating in Democracy", body: "Democracy only works when citizens participate. Voting is the most basic form, but there are many others: joining community organizations, attending town halls, contacting representatives, peaceful protest, and running for office.", sub_points: ["Vote in every election - local, regional, national", "Contact representatives about issues you care about", "Attend public meetings and voice your opinion", "Volunteer for causes and campaigns", "Stay informed through reliable news sources"]}
  ],
  key_points: ["Democracy means 'rule by the people' through voting", "Core values: liberty, equality, justice, tolerance", "Citizens have both rights and responsibilities", "Three branches of government: legislative, executive, judicial", "Separation of powers prevents tyranny", "Active participation is essential for democracy to function"],
  conclusion: "Democracy is not just a form of government - it's a way of life that requires active, informed citizens. You now understand the foundations of democratic governance. Remember: your voice matters, your vote counts, and your participation shapes the future.",
  materials: ["Constitution excerpt (simplified)", "Government structure diagram", "Voter registration information", "Current events articles on civic issues", "Mock election ballot template", "Community organization contact list"],
  objectives: ["Define democracy and distinguish between direct and representative forms", "Identify core democratic values and explain their importance", "Describe the rights and responsibilities of citizens", "Explain the three branches of government and their functions", "Identify ways to participate actively in democracy"],
  duration_mins: 50,
  teacher_tips: "Hold a mock election in class with candidates, debates, and voting. Use current events - have students write letters to representatives about an issue they care about. Invite a local elected official to speak.",
  formative_assessment: "Create a citizen's guide poster showing 3 rights, 3 responsibilities, and 3 ways to participate.",
  summative_assessment: "Essay: 'Why does democracy require active citizens?' Use examples from class and current events.",
  remediation: "For struggling students: Use graphic novels about democracy (e.g., 'Democracy: A Life'). Create simple flowcharts for government structure. Connect to family decision-making as a mini-democracy.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Classroom decision - vote by show of hands vs. let teacher decide. Discuss feelings about each method.", teacher_actions: "Connect to democratic vs. authoritarian decision-making", assessment: "Check understanding of why voting feels fair" },
    { step: 2, activity: "Direct instruction: Democracy definition, types, and core values with visual aids", teacher_actions: "Use world map to show democratic vs. non-democratic countries", assessment: "Quick quiz: define direct vs. representative democracy" },
    { step: 3, activity: "Group activity: Sort cards into 'Rights' and 'Responsibilities' piles, discuss overlaps", teacher_actions: "Facilitate discussion about why responsibilities matter", assessment: "Check that students understand rights-responsibilities connection" },
    { step: 4, activity: "Simulation: Mock town hall meeting on a school issue (e.g., homework policy)", teacher_actions: "Assign roles: citizens, representatives, mayor. Practice democratic participation.", assessment: "Observe participation quality, give feedback on argument construction" },
    { step: 5, activity: "Independent work: Write a letter to a representative about an issue of personal importance", teacher_actions: "Provide template and contact information", assessment: "Check that letters include clear position and reasoning" },
    { step: 6, activity: "Closure: Share one thing learned + one way to participate this week. Preview next lesson on constitution.", teacher_actions: "Encourage real-world application", assessment: "Exit tickets reveal engagement and understanding" }
  ]
};

CREATE lesson_content:11 CONTENT {
  topic_title: "The Industrial Revolution: Causes and Effects",
  subject: "Social Studies",
  term: "Term 1",
  week: 2,
  introduction: "The Industrial Revolution (1760-1840) transformed human civilization from agricultural societies to industrial ones. It began in Britain and spread worldwide, bringing both remarkable progress and significant challenges that still affect us today.",
  content_sections: [
    { header: "What Sparked the Industrial Revolution?", body: "Several factors converged: agricultural improvements freed workers from farms, Britain had abundant coal and iron, the steam engine was invented, and there was growing demand for goods. Capitalism and the profit motive drove innovation.", sub_points: ["Agricultural revolution: new farming techniques increased food production", "Natural resources: coal for power, iron for machines, rivers for transport", "Steam engine: James Watt's improvements (1769) made steam power practical", "Capitalism: private investment in factories and machinery", "Colonial empire: access to raw materials and markets"]},
    { header: "Key Inventions and Innovations", body: "The spinning jenny, power loom, and steam engine revolutionized textile production. The steam locomotive transformed transportation. The factory system replaced cottage industry, concentrating workers in cities.", sub_points: ["Spinning jenny (1764): spun multiple threads at once", "Power loom (1785): automated weaving", "Steam locomotive (1804): fast, reliable land transport", "Factory system: centralized production with division of labor", "Interchangeable parts (Eli Whitney, 1798): standardized manufacturing"]},
    { header: "Social Changes: Urbanization and Class", body: "People moved from rural areas to cities for factory jobs. New social classes emerged: the industrial bourgeoisie (factory owners) and the proletariat (factory workers). Cities grew rapidly, often with poor housing and sanitation.", sub_points: ["Urbanization: cities grew 5-10x in size within decades", "Working class: long hours (12-16 hours/day), dangerous conditions, low pay", "Middle class: managers, engineers, merchants - grew in size and influence", "Child labor: children as young as 6 worked in factories and mines", "Living conditions: overcrowded housing, polluted water, disease"]},
    { header: "Economic Impact", body: "Industrialization created enormous wealth but distributed it unevenly. GDP per capita increased dramatically, but workers' wages rose slowly. Capitalism flourished, but so did calls for reform and workers' rights.", sub_points: ["Massive increase in production and trade", "Wealth concentrated among factory owners and investors", "Creation of global markets and international trade", "Rise of banks and financial institutions", "Beginning of consumer culture"]}
  ],
  key_points: ["Agricultural improvements, resources, and inventions sparked industrialization", "Key inventions: spinning jenny, power loom, steam engine, locomotive", "Urbanization created new social classes and living conditions", "Workers faced dangerous conditions, long hours, and low pay", "Wealth increased enormously but was unevenly distributed", "The Industrial Revolution shaped the modern world"],
  conclusion: "The Industrial Revolution was a turning point in human history. It brought technological progress, economic growth, and modern conveniences, but also exploitation, pollution, and inequality. Understanding this period helps us grapple with similar challenges today: automation, climate change, and economic inequality.",
  materials: ["Industrial Revolution timeline poster", "Images of factories, inventions, and living conditions", "Primary source: Factory Act of 1833 excerpts", "Comparison chart: pre-industrial vs. industrial society", "Documentary clip: 'The Industrial Revolution' (BBC)", "Map: spread of industrialization from Britain"],
  objectives: ["Identify the causes of the Industrial Revolution", "Describe key inventions and their impacts", "Analyze social changes including urbanization and class structure", "Evaluate the economic effects on different social groups", "Connect Industrial Revolution challenges to modern issues"],
  duration_mins: 55,
  teacher_tips: "Use primary sources - show actual Factory Act documents, workers' testimonies, and factory owner letters. Have students debate: 'Was the Industrial Revolution more beneficial or harmful?' Use a T-chart to organize arguments.",
  formative_assessment: "Create a cause-and-effect diagram showing 3 causes and 3 effects of the Industrial Revolution.",
  summative_assessment: "Document-based question: Analyze 3 primary sources (factory owner letter, worker testimony, reform bill) and write an essay evaluating the social impact.",
  remediation: "For struggling students: Use simplified timelines with images. Watch documentary clips instead of reading dense texts. Create a 'day in the life' diary entry from a child's perspective.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: Show images of pre-industrial village vs. industrial city. Ask: 'What changed? How would life be different?'", teacher_actions: "Activate prior knowledge about farming vs. factory work", assessment: "Check understanding of basic differences" },
    { step: 2, activity: "Direct instruction: Causes of Industrial Revolution with timeline and map", teacher_actions: "Emphasize multiple factors coming together, not just inventions", assessment: "Have students identify which cause was most important and defend their choice" },
    { step: 3, activity: "Invention stations: Rotate through 4 stations (spinning jenny, steam engine, locomotive, factory system)", teacher_actions: "Provide hands-on models or simulations at each station", assessment: "Students complete station worksheet with invention, inventor, date, and impact" },
    { step: 4, activity: "Primary source analysis: Read and annotate worker testimony and factory owner letter", teacher_actions: "Model annotation techniques, guide comparison", assessment: "Check that students identify bias and perspective in each source" },
    { step: 5, activity: "Debate prep: 'Was the Industrial Revolution more beneficial or harmful?'", teacher_actions: "Assign positions, provide evidence packets, coach argument construction", assessment: "Review argument outlines for use of evidence and logical reasoning" },
    { step: 6, activity: "Class debate + reflection. Exit ticket: Connect one Industrial Revolution issue to a modern problem.", teacher_actions: "Facilitate debate, summarize key points, preview next lesson on reform movements", assessment: "Exit tickets reveal ability to make historical connections" }
  ]
};

CREATE lesson_content:12 CONTENT {
  topic_title: "Human Rights: Universal Declaration and Global Challenges",
  subject: "Social Studies",
  term: "Term 1",
  week: 3,
  introduction: "Human rights are the basic rights and freedoms that belong to every person in the world, from birth until death. They apply regardless of nationality, sex, ethnicity, color, religion, language, or any other status. Understanding human rights is essential for creating a just world.",
  content_sections: [
    { header: "What Are Human Rights?", body: "Human rights are universal, inalienable, indivisible, and interdependent. Universal means they apply to everyone. Inalienable means they cannot be taken away. Indivisible means all rights are equally important. Interdependent means violating one right often affects others.", sub_points: ["Universal: apply to every human being everywhere", "Inalienable: cannot be surrendered or taken away", "Indivisible: civil, political, economic, social, and cultural rights are equal", "Interdependent: right to education depends on right to food, shelter, safety"]},
    { header: "The Universal Declaration of Human Rights (1948)", body: "After World War II, the United Nations created the UDHR to prevent future atrocities. It has 30 articles covering rights to life, liberty, education, work, fair trial, freedom of thought, and more. Eleanor Roosevelt called it 'the international Magna Carta of all men everywhere.'", sub_points: ["Adopted December 10, 1948 (now Human Rights Day)", "Drafted by representatives from diverse legal and cultural backgrounds", "Not legally binding but forms basis of international human rights law", "Translated into over 500 languages - most translated document in history"]},
    { header: "Categories of Rights", body: "Human rights are grouped into categories: civil and political rights (freedom of speech, voting, fair trial), economic and social rights (education, healthcare, work), and cultural rights (language, religion, cultural practices). All are equally important.", sub_points: ["Civil and political: freedom, equality, participation in government", "Economic and social: standard of living, education, health", "Cultural: identity, language, religion, artistic expression", "Solidarity rights: peace, development, clean environment"]},
    { header: "Current Human Rights Challenges", body: "Despite progress, human rights violations persist worldwide: child labor, human trafficking, discrimination, censorship, torture, and lack of access to education and healthcare. Climate change is increasingly recognized as a human rights issue.", sub_points: ["Children: 152 million children in child labor worldwide", "Women: gender-based violence, unequal pay, limited education access", "Refugees: 26 million refugees denied basic rights in host countries", "Expression: journalists imprisoned, internet censored in many nations", "Environment: climate change threatens right to life, food, water, shelter"]},
    { header: "Defending Human Rights", body: "Individuals, organizations, and governments all play roles in protecting human rights. NGOs like Amnesty International and Human Rights Watch investigate abuses. Governments create laws and institutions. Citizens vote, protest, and advocate.", sub_points: ["International: UN Human Rights Council, International Criminal Court", "National: constitutions, courts, human rights commissions", "Organizations: Amnesty International, Human Rights Watch, UNICEF", "Individuals: voting, protesting, volunteering, donating, speaking out"]}
  ],
  key_points: ["Human rights are universal, inalienable, indivisible, and interdependent", "The UDHR (1948) established 30 fundamental rights for all people", "Rights include civil/political, economic/social, and cultural categories", "Human rights violations persist globally despite progress", "Climate change is an emerging human rights challenge", "Everyone has a role in defending human rights"],
  conclusion: "Human rights are not abstract concepts - they are the foundation of human dignity and freedom. The UDHR was created so that the horrors of World War II would never be repeated. Today, defending human rights means speaking up against injustice, supporting organizations that protect rights, and voting for leaders who prioritize human dignity.",
  materials: ["Simplified UDHR excerpt (student-friendly language)", "Human rights violation case studies (age-appropriate)", "Amnesty International annual report excerpts", "World map showing human rights ratings by country", "Video: 'The Story of Human Rights' (UN)", "Advocacy action planning worksheet"],
  objectives: ["Define human rights and explain their key characteristics", "Describe the origins and significance of the Universal Declaration", "Identify different categories of human rights", "Analyze current global human rights challenges", "Evaluate ways individuals and organizations defend human rights"],
  duration_mins: 55,
  teacher_tips: "Use real, current examples but be sensitive to students' backgrounds. Partner with Amnesty International's education program. Have students write letters to elected officials about a human rights issue. Create a classroom 'Human Rights Wall' with articles and student reflections.",
  formative_assessment: "Choose 3 UDHR articles and explain how they apply to your daily life. Identify one human rights challenge in your community.",
  summative_assessment: "Research project: Investigate one human rights issue globally. Create a presentation with: description, statistics, causes, current efforts, and your advocacy plan.",
  remediation: "For struggling students: Focus on UDHR Articles 1-5 (most fundamental). Use picture books about human rights heroes. Create simple rights-responsibilities matching cards.",
  lesson_steps: [
    { step: 1, activity: "Warm-up: 'What rights do you have as a student?' Brainstorm list, then compare to UDHR.", teacher_actions: "Build on students' lived experience", assessment: "Check prior knowledge of rights concepts" },
    { step: 2, activity: "Direct instruction: Human rights characteristics + UDHR history with primary source images", teacher_actions: "Connect to WWII context, show Eleanor Roosevelt photos", assessment: "Quick write: Why was the UDHR necessary after WWII?" },
    { step: 3, activity: "UDHR exploration: Jigsaw - groups analyze different articles, then teach others", teacher_actions: "Assign articles 1-5, 6-10, 11-15, 16-20, 21-25, 26-30 to 6 groups", assessment: "Check that each group understands their articles deeply" },
    { step: 4, activity: "Case study analysis: Read about Malala Yousafzai or a local human rights defender", teacher_actions: "Guide analysis using 'Who, What, When, Where, Why, How'", assessment: "Have students identify which UDHR articles were violated and defended" },
    { step: 5, activity: "Action planning: Choose one issue, create advocacy plan (letter, poster, social media campaign)", teacher_actions: "Provide templates and contact information for representatives", assessment: "Check that plans are specific, achievable, and grounded in evidence" },
    { step: 6, activity: "Closure: Gallery walk of advocacy plans. Pledge one action item for the month.", teacher_actions: "Celebrate student agency, provide resources for follow-through", assessment: "Exit ticket: 'One thing I will do this month to support human rights'" }
  ]
};
