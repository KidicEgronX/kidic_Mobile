import 'package:flutter/material.dart';

class DoctorPage extends StatefulWidget {
  const DoctorPage({Key? key}) : super(key: key);

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  String selectedSpecialty = 'All Specialties';
  String selectedLocation = 'All Locations';
  TextEditingController searchController = TextEditingController();
  List<Doctor> filteredDoctors = [];

  // Static doctor data
  final List<Doctor> doctors = [
    Doctor(
      id: 'DSC',
      name: 'Dr. Sarah Chen',
      specialty: 'Pediatrician',
      hospital: 'Downtown Medical Center',
      distance: '3.1 km away',
      experience: '12 years experience',
      rating: 4.9,
      reviews: 127,
      languages: ['English', 'Mandarin'],
      nextAvailable: 'Tomorrow 2:00 PM',
      image: 'assets/imgs/doctor1.png',
    ),
    Doctor(
      id: 'DMT',
      name: 'Dr. Michael Torres',
      specialty: 'Developmental Pediatrician',
      hospital: "Children's Hospital",
      distance: '2.7 km away',
      experience: '15 years experience',
      rating: 4.8,
      reviews: 89,
      languages: ['English', 'Spanish'],
      nextAvailable: 'Friday 10:30 AM',
      image: 'assets/imgs/doctor2.png',
    ),
    Doctor(
      id: 'DEW',
      name: 'Dr. Emily Watson',
      specialty: 'Child Psychologist',
      hospital: 'Wellness Center',
      distance: '1.8 km away',
      experience: '8 years experience',
      rating: 4.9,
      reviews: 156,
      languages: ['English', 'French'],
      nextAvailable: 'Monday 3:00 PM',
      image: 'assets/imgs/doctor3.png',
    ),
    Doctor(
      id: 'DJR',
      name: 'Dr. James Rodriguez',
      specialty: 'Pediatric Nutritionist',
      hospital: 'Family Health Clinic',
      distance: '4.2 km away',
      experience: '10 years experience',
      rating: 4.7,
      reviews: 73,
      languages: ['English', 'Spanish'],
      nextAvailable: 'Wednesday 11:00 AM',
      image: 'assets/imgs/doctor4.png',
    ),
  ];

  final List<String> specialties = [
    'All Specialties',
    'Pediatrician',
    'Developmental Pediatrician',
    'Child Psychologist',
    'Pediatric Nutritionist',
  ];

  final List<String> locations = [
    'All Locations',
    'Downtown Medical Center',
    "Children's Hospital",
    'Wellness Center',
    'Family Health Clinic',
  ];

  @override
  void initState() {
    super.initState();
    filteredDoctors = doctors;
  }

  void _filterDoctors() {
    setState(() {
      filteredDoctors = doctors.where((doctor) {
        final matchesSearch =
            searchController.text.isEmpty ||
            doctor.name.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            doctor.specialty.toLowerCase().contains(
              searchController.text.toLowerCase(),
            );

        final matchesSpecialty =
            selectedSpecialty == 'All Specialties' ||
            doctor.specialty == selectedSpecialty;

        final matchesLocation =
            selectedLocation == 'All Locations' ||
            doctor.hospital == selectedLocation;

        return matchesSearch && matchesSpecialty && matchesLocation;
      }).toList();
    });
  }

  String _getShortSpecialtyName(String specialty) {
    switch (specialty) {
      case 'All Specialties':
        return 'All Specialties';
      case 'Developmental Pediatrician':
        return 'Dev. Ped.';
      case 'Pediatric Nutritionist':
        return 'Ped. Nutri.';
      case 'Child Psychologist':
        return 'Child Psych.';
      default:
        return specialty;
    }
  }

  String _getShortLocationName(String location) {
    switch (location) {
      case 'All Locations':
        return 'All Locations';
      case 'Downtown Medical Center':
        return 'Downtown';
      case "Children's Hospital":
        return "Children's";
      case 'Family Health Clinic':
        return 'Family';
      case 'Wellness Center':
        return 'Wellness';
      default:
        return location;
    }
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) getShortName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.black, fontSize: 13),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              getShortName(item),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMoreFiltersButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Show only icon on very small screens to prevent overflow
        final showTextOnly = constraints.maxWidth < 400;

        return GestureDetector(
          onTap: () {
            _showMoreFiltersSheet();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showTextOnly ? 12 : 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: showTextOnly
                ? const Icon(Icons.tune, color: Colors.grey, size: 18)
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, color: Colors.grey, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'More Filters',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _showMoreFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'More Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterOption('Rating (High to Low)', true),
                    _buildFilterOption('Distance (Nearest first)', false),
                    _buildFilterOption('Experience (Most experienced)', false),
                    _buildFilterOption('Price (Low to High)', false),
                    const SizedBox(height: 24),
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterOption('Available Today', false),
                    _buildFilterOption('Available This Week', false),
                    _buildFilterOption('Available This Month', false),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterDoctors();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find Doctors',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect with pediatric specialists and book appointments',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => _filterDoctors(),
                    decoration: const InputDecoration(
                      hintText: 'Search doctors or clinics...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters Row - Mobile Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    // For very small screens, stack filters vertically
                    if (constraints.maxWidth < 350) {
                      return Column(
                        children: [
                          _buildDropdownFilter(
                            value: selectedSpecialty,
                            items: specialties,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedSpecialty = newValue!;
                              });
                              _filterDoctors();
                            },
                            getShortName: _getShortSpecialtyName,
                          ),
                          const SizedBox(height: 8),
                          _buildDropdownFilter(
                            value: selectedLocation,
                            items: locations,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedLocation = newValue!;
                              });
                              _filterDoctors();
                            },
                            getShortName: _getShortLocationName,
                          ),
                          const SizedBox(height: 8),
                          _buildMoreFiltersButton(),
                        ],
                      );
                    }

                    // For normal screens, use horizontal layout
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildDropdownFilter(
                            value: selectedSpecialty,
                            items: specialties,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedSpecialty = newValue!;
                              });
                              _filterDoctors();
                            },
                            getShortName: _getShortSpecialtyName,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: _buildDropdownFilter(
                            value: selectedLocation,
                            items: locations,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedLocation = newValue!;
                              });
                              _filterDoctors();
                            },
                            getShortName: _getShortLocationName,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(flex: 1, child: _buildMoreFiltersButton()),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Doctor List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDoctors.length + 1, // +1 for the footer
              itemBuilder: (context, index) {
                if (index == filteredDoctors.length) {
                  // Footer - Book Through Vezeeta
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Book Through Vezeeta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'For seamless appointment booking, you\'ll be redirected to Vezeeta.com to complete your reservation with your selected doctor.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final doctor = filteredDoctors[index];
                return DoctorCard(
                  doctor: doctor,
                  onBookAppointment: () => _bookAppointment(doctor),
                  onCall: () => _callDoctor(doctor),
                  onMessage: () => _messageDoctor(doctor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(Doctor doctor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Book Appointment with ${doctor.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next available: ${doctor.nextAvailable}'),
              const SizedBox(height: 8),
              Text('Location: ${doctor.hospital}'),
              const SizedBox(height: 8),
              Text('Specialty: ${doctor.specialty}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment booked with ${doctor.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Book Now'),
            ),
          ],
        );
      },
    );
  }

  void _callDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${doctor.name}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _messageDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${doctor.name}...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onBookAppointment;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const DoctorCard({
    Key? key,
    required this.doctor,
    required this.onBookAppointment,
    required this.onCall,
    required this.onMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    doctor.id,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      doctor.distance,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              doctor.rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ' (${doctor.reviews})',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          doctor.experience,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: doctor.languages
                          .map(
                            (language) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                language,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Next Available
              Container(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.schedule, color: Colors.grey, size: 14),
                    const SizedBox(height: 2),
                    Text(
                      'Next available:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 8),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      doctor.nextAvailable,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: onBookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 120) {
                        // Show compact version for very small buttons
                        return const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 14),
                            SizedBox(width: 4),
                            Text('Book', style: TextStyle(fontSize: 12)),
                          ],
                        );
                      }
                      // Show full version for larger buttons
                      return const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Book Appointment',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCall,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.phone, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onMessage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.message, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final String distance;
  final String experience;
  final double rating;
  final int reviews;
  final List<String> languages;
  final String nextAvailable;
  final String image;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.distance,
    required this.experience,
    required this.rating,
    required this.reviews,
    required this.languages,
    required this.nextAvailable,
    required this.image,
  });
}
