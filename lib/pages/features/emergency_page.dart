import 'package:flutter/material.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Categories for filtering
  final List<String> _categories = [
    'All',
    'High Priority',
    'Medium Priority',
    'Low Priority',
  ];

  // Emergency protocol data
  final List<Map<String, dynamic>> _emergencyProtocols = [
    {
      'title': 'Choking',
      'subtitle': 'Complete or partial airway obstruction',
      'priority': 'High Priority',
      'color': Colors.red,
      'colorName': 'HIGH',
      'icon': Icons.warning,
      'symptoms': [
        'Cannot speak or cry',
        'Difficulty breathing',
        'Blue lips or face',
        'Grabbing at throat',
      ],
      'immediateActions': [
        'Call 911 immediately',
        'For infants: Back blows and chest thrusts',
        'For children: Heimlich maneuver',
        'Do not put fingers in mouth',
      ],
      'fullDescription': '''
CHOKING EMERGENCY PROTOCOL

RECOGNITION:
- Child cannot speak, cry, or cough
- Difficulty breathing or wheezing sounds
- Blue coloration around lips or face
- Universal choking sign (hands at throat)
- Loss of consciousness (severe cases)

IMMEDIATE RESPONSE:

For Infants (under 1 year):
1. Hold baby face-down on your forearm
2. Support head and neck with your hand
3. Give 5 sharp back blows between shoulder blades
4. Turn baby over, give 5 chest compressions
5. Repeat until object dislodged or baby unconscious

For Children (over 1 year):
1. Stand behind child, wrap arms around waist
2. Make fist with one hand, place above navel
3. Grasp fist with other hand
4. Give quick upward thrusts into abdomen
5. Continue until object expelled or child unconscious

NEVER:
- Put fingers in mouth to retrieve object
- Give water or food
- Perform abdominal thrusts on infants
- Give up - continue until help arrives

Call emergency services immediately while performing these steps.
      ''',
    },
    {
      'title': 'Severe Allergic Reaction',
      'subtitle': 'Anaphylaxis - life-threatening allergic response',
      'priority': 'High Priority',
      'color': Colors.red,
      'colorName': 'HIGH',
      'icon': Icons.healing,
      'symptoms': [
        'Difficulty breathing',
        'Swelling of face/throat',
        'Rapid pulse',
        'Skin rash or hives',
      ],
      'immediateActions': [
        'Call 911 immediately',
        'Use EpiPen if available',
        'Keep child calm and lying down',
        'Monitor breathing closely',
      ],
      'fullDescription': '''
SEVERE ALLERGIC REACTION (ANAPHYLAXIS)

RECOGNITION:
- Difficulty breathing or wheezing
- Swelling of face, lips, tongue, or throat
- Rapid, weak pulse
- Widespread skin rash, hives, or itching
- Nausea, vomiting, or diarrhea
- Dizziness or loss of consciousness
- Sense of impending doom

IMMEDIATE RESPONSE:
1. Call 911 immediately
2. If EpiPen available, use immediately:
   - Remove safety cap
   - Hold firmly against outer thigh
   - Press until it clicks, hold for 10 seconds
3. Keep child lying down with legs elevated
4. Loosen tight clothing around neck and waist
5. Monitor breathing and pulse constantly
6. Be prepared to perform CPR if needed
7. Second dose of epinephrine may be needed in 5-15 minutes

AFTER TREATMENT:
- Go to hospital even if symptoms improve
- Epinephrine effects are temporary
- Reaction can return (biphasic reaction)

PREVENTION:
- Identify and avoid known allergens
- Always carry prescribed medications
- Wear medical alert bracelet
- Inform schools and caregivers of allergies
      ''',
    },
    {
      'title': 'High Fever',
      'subtitle': 'Body temperature above 104°F (40°C)',
      'priority': 'Medium Priority',
      'color': Colors.orange,
      'colorName': 'MED',
      'icon': Icons.thermostat,
      'symptoms': [
        'Temperature over 104°F',
        'Lethargy or confusion',
        'Severe headache',
        'Difficulty breathing',
      ],
      'immediateActions': [
        'Remove excess clothing',
        'Give fever reducer if appropriate',
        'Cool bath or wet cloths',
        'Encourage fluid intake',
      ],
      'fullDescription': '''
HIGH FEVER PROTOCOL

RECOGNITION:
- Rectal temperature over 104°F (40°C)
- Extreme lethargy or unusual drowsiness
- Confusion or delirium
- Severe headache
- Difficulty breathing
- Persistent crying (infants)
- Stiff neck or back
- Severe stomach pain

IMMEDIATE RESPONSE:
1. Remove excess clothing and blankets
2. Give appropriate dose of fever reducer:
   - Acetaminophen or ibuprofen as directed
   - Never give aspirin to children
3. Cool the body gradually:
   - Lukewarm bath or shower
   - Cool, wet cloths on forehead, wrists, neck
   - Use fan for air circulation
4. Encourage frequent small sips of fluids
5. Monitor temperature every 30 minutes

SEEK EMERGENCY CARE IF:
- Temperature remains above 104°F after treatment
- Signs of dehydration appear
- Severe headache with stiff neck
- Difficulty breathing or rapid breathing
- Persistent vomiting
- Signs of confusion or seizure

FOR INFANTS (under 3 months):
- Any fever warrants immediate medical attention
- Do not give medications without consulting doctor
- Seek emergency care for temperature over 100.4°F (38°C)
      ''',
    },
    {
      'title': 'Burns',
      'subtitle': 'Thermal, chemical, or electrical injury to skin',
      'priority': 'Medium Priority',
      'color': Colors.orange,
      'colorName': 'MED',
      'icon': Icons.local_fire_department,
      'symptoms': [
        'Red, painful skin',
        'Blisters forming',
        'White or charred skin',
        'Severe pain or no pain',
      ],
      'immediateActions': [
        'Cool running water for 10-20 minutes',
        'Remove from heat source',
        'Cover with clean cloth',
        'Do not apply ice or butter',
      ],
      'fullDescription': '''
BURN INJURY PROTOCOL

RECOGNITION:
First-degree burns:
- Red, painful skin
- No blisters
- Skin turns white when pressed

Second-degree burns:
- Red, painful, swollen skin
- Blisters present
- Wet or shiny appearance

Third-degree burns:
- White, brown, or charred skin
- Leathery texture
- Little to no pain (nerve damage)

IMMEDIATE RESPONSE:
1. Remove child from heat source safely
2. For thermal burns:
   - Run cool (not cold) water over burn for 10-20 minutes
   - Remove clothing from burned area (if not stuck)
   - Do not break blisters
3. For chemical burns:
   - Flush with large amounts of water
   - Remove contaminated clothing
   - Continue flushing for 20 minutes minimum
4. Cover burn with clean, dry cloth
5. Give over-the-counter pain medication if appropriate

NEVER:
- Apply ice, butter, or home remedies
- Break blisters
- Remove clothing stuck to skin
- Use cotton balls on open burns

SEEK EMERGENCY CARE FOR:
- Burns larger than child's palm
- Burns on face, hands, feet, or genitals
- Third-degree burns of any size
- Electrical or chemical burns
- Signs of infection (fever, pus, increased pain)
      ''',
    },
    {
      'title': 'Poisoning',
      'subtitle': 'Ingestion of harmful substances',
      'priority': 'High Priority',
      'color': Colors.red,
      'colorName': 'HIGH',
      'icon': Icons.dangerous,
      'symptoms': [
        'Nausea and vomiting',
        'Drowsiness or confusion',
        'Difficulty breathing',
        'Burns around mouth',
      ],
      'immediateActions': [
        'Call Poison Control: 1-800-222-1222',
        'Do not induce vomiting',
        'Remove substance from mouth',
        'Save container/packaging',
      ],
      'fullDescription': '''
POISONING EMERGENCY PROTOCOL

RECOGNITION:
- Nausea, vomiting, or diarrhea
- Drowsiness, confusion, or unconsciousness
- Difficulty breathing
- Burns or redness around mouth, lips, or tongue
- Strange breath odor
- Empty containers or packaging nearby
- Unusual behavior or symptoms

IMMEDIATE RESPONSE:
1. Call Poison Control Center: 1-800-222-1222
2. Have this information ready:
   - Child's age and weight
   - Name of substance ingested
   - Amount consumed (if known)
   - Time of ingestion
   - Child's current symptoms

3. Follow Poison Control instructions exactly
4. If unconscious or not breathing, call 911 first
5. Remove any remaining substance from mouth with finger sweep
6. Save container, packaging, or vomit sample for medical team

DO NOT:
- Induce vomiting unless instructed
- Give milk, water, or food unless told to do so
- Give activated charcoal unless prescribed
- Make child walk or move around

SPECIAL CONSIDERATIONS:
Corrosive substances (bleach, drain cleaner):
- Give small sips of water or milk
- Do not induce vomiting

Petroleum products (gasoline, kerosene):
- Do not induce vomiting (aspiration risk)
- Seek immediate medical care

PREVENTION:
- Store all chemicals and medications safely
- Use child-proof locks and caps
- Keep original containers
- Post Poison Control number where visible
      ''',
    },
    {
      'title': 'Minor Cuts',
      'subtitle': 'Small wounds requiring basic first aid',
      'priority': 'Low Priority',
      'color': Colors.green,
      'colorName': 'LOW',
      'icon': Icons.healing,
      'symptoms': [
        'Small bleeding wound',
        'Clean edges',
        'Minimal depth',
        'No severe pain',
      ],
      'immediateActions': [
        'Clean hands first',
        'Apply direct pressure to stop bleeding',
        'Clean wound gently',
        'Apply bandage',
      ],
      'fullDescription': '''
MINOR CUTS PROTOCOL

RECOGNITION:
- Small wound less than 1/2 inch long
- Clean, straight edges
- Minimal bleeding
- No deep tissue visible
- No foreign objects embedded
- Child is alert and responsive

IMMEDIATE RESPONSE:
1. Wash your hands thoroughly with soap and water
2. Apply direct pressure with clean cloth to stop bleeding
3. Once bleeding stops:
   - Rinse wound gently with clean water
   - Pat dry with clean cloth
   - Apply thin layer of antibiotic ointment if available
4. Cover with sterile adhesive bandage
5. Elevate injured area if possible

WOUND CARE:
- Change bandage daily or when wet/dirty
- Keep wound clean and dry
- Check for signs of infection daily
- Remove bandage after 2-3 days to air dry

SIGNS OF INFECTION (seek medical care):
- Increased redness or swelling
- Red streaking from wound
- Pus or unusual discharge
- Fever
- Increased pain after initial improvement

WHEN TO SEEK MEDICAL CARE:
- Cut is deeper than 1/4 inch
- Edges of wound gape open
- Bleeding won't stop after 10 minutes of pressure
- Cut is from dirty or rusty object
- Last tetanus shot was more than 5 years ago
- Signs of infection appear

PREVENTION:
- Keep first aid supplies readily available
- Supervise children during activities
- Maintain safe environment
- Teach children about sharp object safety
      ''',
    },
    {
      'title': 'Nosebleed',
      'subtitle': 'Bleeding from nasal passages',
      'priority': 'Low Priority',
      'color': Colors.green,
      'colorName': 'LOW',
      'icon': Icons.face,
      'symptoms': [
        'Blood from nose',
        'Usually from one nostril',
        'May have clots',
        'Typically not painful',
      ],
      'immediateActions': [
        'Have child sit upright',
        'Lean head slightly forward',
        'Pinch soft part of nose',
        'Apply pressure for 10-15 minutes',
      ],
      'fullDescription': '''
NOSEBLEED PROTOCOL

RECOGNITION:
- Blood flowing from one or both nostrils
- May be bright red or dark
- Can range from drops to steady flow
- May include small clots
- Usually not associated with severe pain

IMMEDIATE RESPONSE:
1. Keep child calm and upright
2. Have child sit and lean slightly forward
   - This prevents blood from running down throat
   - Reduces nausea and choking risk
3. Pinch the soft part of nose (not the bridge)
4. Apply steady pressure for 10-15 minutes
5. Breathe through mouth during this time
6. Apply cold compress to bridge of nose
7. After bleeding stops, avoid nose blowing for several hours

DO NOT:
- Tilt head back (causes blood to run down throat)
- Pack nose with tissues or cotton
- Check frequently if bleeding has stopped
- Allow child to lie down

SEEK MEDICAL CARE IF:
- Bleeding continues after 20 minutes of pressure
- Bleeding is result of injury to head or face
- Large amount of blood loss
- Difficulty breathing
- Signs of excessive blood loss (dizziness, weakness)
- Frequent recurring nosebleeds

COMMON CAUSES:
- Dry air (especially in winter)
- Nose picking or rubbing
- Allergies or cold symptoms
- Minor injury to nose
- Certain medications

PREVENTION:
- Use humidifier in dry environments
- Apply petroleum jelly inside nostrils
- Keep fingernails short
- Treat allergies appropriately
- Avoid excessive nose blowing
      ''',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Protocols',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with description
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: const Text(
              'Quick reference guide for child emergency situations',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(
                  size.width * 0.05,
                ), // Responsive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(size),

                    SizedBox(height: size.height * 0.03),

                    // Category Tabs
                    _buildCategoryTabs(size),

                    SizedBox(height: size.height * 0.04),

                    // Emergency Protocol Cards
                    _buildEmergencyCards(size),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Size size) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: size.width * 0.04),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search emergency protocols...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: size.width * 0.04,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
            size: size.width * 0.05,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                    size: size.width * 0.05,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.02,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(Size size) {
    return SizedBox(
      height: size.height * 0.06,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: size.width * 0.03),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.015,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red[100] : Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.06),
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.red[700] : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyCards(Size size) {
    // Filter cards based on selected category and search query
    List<Map<String, dynamic>> filteredCards = _emergencyProtocols;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredCards = filteredCards
          .where((card) => card['priority'] == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredCards = filteredCards.where((card) {
        final title = card['title'].toString().toLowerCase();
        final subtitle = card['subtitle'].toString().toLowerCase();
        final symptoms = (card['symptoms'] as List<String>)
            .join(' ')
            .toLowerCase();
        final actions = (card['immediateActions'] as List<String>)
            .join(' ')
            .toLowerCase();

        return title.contains(_searchQuery) ||
            subtitle.contains(_searchQuery) ||
            symptoms.contains(_searchQuery) ||
            actions.contains(_searchQuery);
      }).toList();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.width > 600
            ? 2
            : 1, // 2 columns on tablets, 1 on phones
        childAspectRatio: size.width > 600 ? 1.0 : 1.1, // Increase card height
        crossAxisSpacing: size.width * 0.04,
        mainAxisSpacing: size.height * 0.025,
      ),
      itemCount: filteredCards.length,
      itemBuilder: (context, index) {
        return _buildEmergencyCard(size, filteredCards[index]);
      },
    );
  }

  Widget _buildEmergencyCard(Size size, Map<String, dynamic> emergency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency header with priority
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        emergency['icon'],
                        color: emergency['color'],
                        size: size.width * 0.06,
                      ),
                      SizedBox(width: size.width * 0.02),
                      Expanded(
                        child: Text(
                          emergency['title'],
                          style: TextStyle(
                            fontSize: size.width * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.025,
                    vertical: size.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: emergency['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Text(
                    emergency['colorName'],
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      fontWeight: FontWeight.w600,
                      color: emergency['color'],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.015),

            // Subtitle
            Text(
              emergency['subtitle'],
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // Symptoms section
            Text(
              'Key Symptoms:',
              style: TextStyle(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: size.height * 0.01),

            // Symptoms chips
            Wrap(
              spacing: size.width * 0.02,
              runSpacing: size.height * 0.008,
              children: (emergency['symptoms'] as List<String>).take(3).map((
                symptom,
              ) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.025,
                    vertical: size.height * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: emergency['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(size.width * 0.015),
                  ),
                  child: Text(
                    symptom,
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: emergency['color'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: size.height * 0.02),

            // View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEmergencyDetails(emergency);
                },
                icon: Icon(
                  Icons.info_outline,
                  size: size.width * 0.04,
                  color: Colors.white,
                ),
                label: Text(
                  'View Protocol',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: emergency['color'],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.025),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDetails(Map<String, dynamic> emergency) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EmergencyDetailsDialog(emergency: emergency);
      },
    );
  }
}

class EmergencyDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> emergency;

  const EmergencyDetailsDialog({super.key, required this.emergency});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.all(size.width * 0.05),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size.width * 0.04),
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: emergency['color'],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size.width * 0.04),
                  topRight: Radius.circular(size.width * 0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          emergency['icon'],
                          color: Colors.white,
                          size: size.width * 0.06,
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: Text(
                            emergency['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: size.width * 0.06,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.height * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: emergency['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(size.width * 0.05),
                      ),
                      child: Text(
                        emergency['priority'].toUpperCase(),
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.bold,
                          color: emergency['color'],
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Symptoms section
                    _buildDetailSection(
                      size,
                      'SYMPTOMS TO RECOGNIZE',
                      emergency['symptoms'],
                      emergency['color'],
                      Icons.visibility,
                    ),

                    SizedBox(height: size.height * 0.03),

                    // Immediate actions section
                    _buildDetailSection(
                      size,
                      'IMMEDIATE ACTIONS',
                      emergency['immediateActions'],
                      emergency['color'],
                      Icons.flash_on,
                    ),

                    SizedBox(height: size.height * 0.03),

                    // Full protocol
                    Text(
                      'COMPLETE PROTOCOL',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: emergency['color'],
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(size.width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        emergency['fullDescription'],
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    Size size,
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: size.width * 0.05),
            SizedBox(width: size.width * 0.02),
            Text(
              title,
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: size.height * 0.015),
        ...items
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.01),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: size.width * 0.015,
                      height: size.width * 0.015,
                      margin: EdgeInsets.only(
                        top: size.height * 0.008,
                        right: size.width * 0.03,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: size.width * 0.038,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
