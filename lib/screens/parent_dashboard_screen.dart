import 'package:achiver_app/screens/reports_zone_page.dart';
import 'package:flutter/material.dart';
import 'leave_application_screen.dart';
import 'contact_teacher_screen.dart';
import 'parent_profile_page.dart';
import 'fee_payments_screen.dart';
import 'parent_progress_page.dart' as parent_progress;
import '../services/parent_service.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ParentDashboardScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _isLoadingChildren = true;
  String? _childrenError;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    setState(() {
      _isLoadingChildren = true;
      _childrenError = null;
    });
    try {
      print('Fetching parent profile...');
      final parentProfile = await ParentService()
          .getParentProfile()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Loading children timed out. Please check your connection.';
      });
      print('Parent profile fetched: ' + parentProfile.toString());
      final children =
          List<Map<String, dynamic>>.from(parentProfile['children'] ?? []);
      print('Children loaded: ${children.length}');
      setState(() {
        _children = children;
        _isLoadingChildren = false;
      });
    } catch (e) {
      print('Error loading children: $e');
      setState(() {
        _childrenError = 'Failed to load children: $e';
        _isLoadingChildren = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          title: const Text(
            'Parent Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChildInfoCard(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildAttendanceAndGrades(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue[800], size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eswar Kumar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'CSE-B •21BF1A05A9',
                  style: TextStyle(
                    color: Colors.blue[50],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingChildren)
          const Center(child: CircularProgressIndicator()),
        if (_childrenError != null)
          Center(
              child:
                  Text(_childrenError!, style: TextStyle(color: Colors.red))),
        if (!_isLoadingChildren && _childrenError == null)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            children: [
              _buildActionButton(
                'Leave\nApplication',
                Icons.event_busy_rounded,
                Colors.orange[400]!,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveApplicationScreen(),
                  ),
                ),
              ),
              _buildActionButton(
                'Contact\nTeacher',
                Icons.chat_bubble_outline_rounded,
                Colors.green[400]!,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactTeacherScreen(),
                  ),
                ),
              ),
              _buildActionButton(
                'Progress',
                Icons.assessment_rounded,
                Colors.purple[400]!,
                onTap: () async {
                  if (_children.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No children found for this parent.')),
                    );
                    return;
                  }
                  if (_children.length == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            parent_progress.ProgressPage(child: _children[0]),
                      ),
                    );
                  } else {
                    final selected = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: const Text('Select Child'),
                          children: _children.map((child) {
                            final name =
                                child['name'] ?? child['fullName'] ?? 'Unknown';
                            return SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, child),
                              child: Text(name),
                            );
                          }).toList(),
                        );
                      },
                    );
                    if (selected != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              parent_progress.ProgressPage(child: selected),
                        ),
                      );
                    }
                  }
                },
              ),
              _buildActionButton(
                'Fee\nPayments',
                Icons.payment_rounded,
                Colors.blue[400]!,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeePaymentsScreen(),
                  ),
                ),
              ),
            ],
          ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          children: [
            _buildActionButton(
              'Leave\nApplication',
              Icons.event_busy_rounded,
              Colors.orange[400]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveApplicationScreen(),
                ),
              ),
            ),
            _buildActionButton(
              'Contact\nTeacher',
              Icons.chat_bubble_outline_rounded,
              Colors.green[400]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactTeacherScreen(
                    showExitConfirmation: false,
                    previousScreen: const ParentDashboardScreen(),
                  ),
                ),
              ),
            ),
            _buildActionButton(
              'Progress',
              Icons.assessment_rounded,
              Colors.purple[400]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsZonePage(),
                ),
              ),
            ),
            _buildActionButton(
              'Fee\nPayments',
              Icons.payment_rounded,
              Colors.blue[400]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeePaymentsScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceAndGrades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Attendance',
                '95%',
                Icons.calendar_today,
                Colors.green,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Average Grade',
                'A',
                Icons.grade,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color[700], size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
