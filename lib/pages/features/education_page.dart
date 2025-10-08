import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Categories for filtering
  final List<String> _categories = [
    'All',
    'Montessori Activities',
    'Parenting Tips',
    'Age-Specific Guides',
  ];

  // Educational content data based on the design
  final List<Map<String, dynamic>> _ageGroups = [
    {
      'title': 'Sensory Activities',
      'subtitle':
          'Montessori-inspired sensory activities for early development',
      'color': Colors.blue,
      'colorName': 'Montessori',
      'category': 'Montessori Activities',
      'keyTopics': [
        'Texture Exploration',
        'Sound Recognition',
        'Visual Stimulation',
        'Tactile Play',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Montessori sensory activities
    },
    {
      'title': 'Practical Life Skills',
      'subtitle': 'Montessori practical life activities for independence',
      'color': Colors.green,
      'colorName': 'Montessori',
      'category': 'Montessori Activities',
      'keyTopics': [
        'Pouring Exercises',
        'Sorting Activities',
        'Self-Care Tasks',
        'Food Preparation',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Montessori practical life
    },
    {
      'title': 'Positive Discipline',
      'subtitle': 'Expert parenting tips for effective child guidance',
      'color': Colors.purple,
      'colorName': 'Parenting',
      'category': 'Parenting Tips',
      'keyTopics': [
        'Setting Boundaries',
        'Communication Skills',
        'Emotional Regulation',
        'Conflict Resolution',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Parenting tips
    },
    {
      'title': '0-3 Years Development',
      'subtitle': 'Age-specific developmental milestones and activities',
      'color': Colors.orange,
      'colorName': 'Age Guide',
      'category': 'Age-Specific Guides',
      'keyTopics': [
        'Motor Skills',
        'Language Development',
        'Social Skills',
        'Cognitive Growth',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Age-specific guide
    },
    {
      'title': 'Mathematics Activities',
      'subtitle': 'Montessori math concepts and number recognition',
      'color': Colors.teal,
      'colorName': 'Montessori',
      'category': 'Montessori Activities',
      'keyTopics': [
        'Number Recognition',
        'Counting Exercises',
        'Shape Sorting',
        'Pattern Making',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Montessori math
    },
    {
      'title': 'Sleep & Routine',
      'subtitle': 'Creating healthy sleep habits and daily routines',
      'color': Colors.indigo,
      'colorName': 'Parenting',
      'category': 'Parenting Tips',
      'keyTopics': [
        'Bedtime Routines',
        'Sleep Training',
        'Daily Structure',
        'Transition Times',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Sleep and routine tips
    },
    {
      'title': '3-6 Years Milestones',
      'subtitle': 'Preschool developmental expectations and activities',
      'color': Colors.red,
      'colorName': 'Age Guide',
      'category': 'Age-Specific Guides',
      'keyTopics': [
        'Pre-Reading Skills',
        'Fine Motor Development',
        'Social Independence',
        'Emotional Maturity',
      ],
      'youtubeUrl':
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // 3-6 years guide
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
          'Educational Content',
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
              'Montessori-inspired activities and expert parenting guidance',
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

                    // Age Group Cards
                    _buildAgeGroupCards(size),
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
          hintText: 'Search activities, tips, or topics...',
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
                  color: isSelected ? Colors.blue[100] : Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.06),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
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
                      color: isSelected ? Colors.blue[700] : Colors.grey[700],
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

  Widget _buildAgeGroupCards(Size size) {
    // Filter cards based on selected category and search query
    List<Map<String, dynamic>> filteredCards = _ageGroups;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredCards = filteredCards
          .where((card) => card['category'] == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredCards = filteredCards.where((card) {
        final title = card['title'].toString().toLowerCase();
        final subtitle = card['subtitle'].toString().toLowerCase();
        final keyTopics = (card['keyTopics'] as List<String>)
            .join(' ')
            .toLowerCase();
        final category = card['category'].toString().toLowerCase();

        return title.contains(_searchQuery) ||
            subtitle.contains(_searchQuery) ||
            keyTopics.contains(_searchQuery) ||
            category.contains(_searchQuery);
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
        return _buildAgeGroupCard(size, filteredCards[index]);
      },
    );
  }

  Widget _buildAgeGroupCard(Size size, Map<String, dynamic> ageGroup) {
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
            // Age group header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ageGroup['title'],
                    style: TextStyle(
                      fontSize: size.width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.025,
                    vertical: size.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: ageGroup['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Text(
                    ageGroup['colorName'],
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      fontWeight: FontWeight.w600,
                      color: ageGroup['color'],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.015),

            // Subtitle
            Text(
              ageGroup['subtitle'],
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // Key Topics section
            Text(
              'Key Topics:',
              style: TextStyle(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: size.height * 0.01),

            // Key topics chips
            Wrap(
              spacing: size.width * 0.02,
              runSpacing: size.height * 0.008,
              children: (ageGroup['keyTopics'] as List<String>).map((topic) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.025,
                    vertical: size.height * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(size.width * 0.015),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: size.height * 0.02),

            // Watch Video Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openYouTubeVideo(ageGroup['youtubeUrl']);
                },
                icon: Icon(
                  Icons.play_circle_filled,
                  size: size.width * 0.04,
                  color: Colors.white,
                ),
                label: Text(
                  'Watch Video',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ageGroup['color'],
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

  void _openYouTubeVideo(String videoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return YouTubeVideoPopup(videoUrl: videoUrl);
      },
    );
  }
}

class YouTubeVideoPopup extends StatefulWidget {
  final String videoUrl;

  const YouTubeVideoPopup({super.key, required this.videoUrl});

  @override
  State<YouTubeVideoPopup> createState() => _YouTubeVideoPopupState();
}

class _YouTubeVideoPopupState extends State<YouTubeVideoPopup> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    String videoId = _getVideoId(widget.videoUrl);
    String htmlContent =
        '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                background-color: #000;
                height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
            }
            .video-container {
                position: relative;
                width: 100%;
                height: 0;
                padding-bottom: 56.25%; /* 16:9 aspect ratio */
            }
            iframe {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                border: none;
            }
        </style>
    </head>
    <body>
        <div class="video-container">
            <iframe 
                src="https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&showinfo=0&controls=1&modestbranding=1&playsinline=1"
                allowfullscreen
                allow="autoplay; encrypted-media; picture-in-picture">
            </iframe>
        </div>
    </body>
    </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  String _getVideoId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)',
      caseSensitive: false,
    );
    Match? match = regExp.firstMatch(url);
    return match?.group(1) ?? 'dQw4w9WgXcQ'; // fallback video ID
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(size.width * 0.05),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(size.width * 0.04),
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Educational Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
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

            // Video WebView
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size.width * 0.04),
                  bottomRight: Radius.circular(size.width * 0.04),
                ),
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                              SizedBox(height: size.height * 0.02),
                              Text(
                                'Loading video...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.04,
                                ),
                              ),
                            ],
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
}
