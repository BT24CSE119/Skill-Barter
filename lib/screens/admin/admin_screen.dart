import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';
import 'admin_skills_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}
Future<void> sendReplyNotification({
  required String userId,
  required String message,
}) async {
  await FirebaseFirestore.instance.collection("notifications").add({
    "userId": userId, // 🔥 who will receive
    "title": "Support Response",
    "message": message,
    "timestamp": FieldValue.serverTimestamp(),
    "read": false,
    "type": "report_reply",
  });
}

class _AdminScreenState extends State<AdminScreen> {
  int totalUsers = 0;
  int newUsers = 0;
  int sessionsToday = 0;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  

  /// 🔥 FIXED: moved inside class
  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadStats() async {
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();

    totalUsers = usersSnap.docs.length;

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    newUsers = usersSnap.docs.where((doc) {
      final data = doc.data();
      final created = data['createdAt'];

      if (created == null) return false;

      final date = (created as Timestamp).toDate();
      return date.isAfter(weekAgo);
    }).length;

    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final sessionsSnap =
        await FirebaseFirestore.instance.collection('sessions').get();

    sessionsToday = sessionsSnap.docs.where((doc) {
      final data = doc.data();
      final time = data['time'];

      if (time == null) return false;

      final date = (time as Timestamp).toDate();
      return date.isAfter(todayStart);
    }).length;

    setState(() {});
  }

 Widget _buildCard(String title, int value, Color color) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeInOut,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),

      /// 🔥 GRADIENT BACKGROUND
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.85),
          color.withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),

      /// 🔥 GLOW EFFECT
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.6),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 TITLE
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 10),

        /// 🔥 VALUE
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  /// 🔥 DASHBOARD VIEW
 Widget _dashboardView() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 STATS
        Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () {
          // 👉 optional action (future use)
        },
        child: _buildCard("Total Users", totalUsers, Colors.blue),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: GestureDetector(
        onTap: () {},
        child: _buildCard("New Users (7d)", newUsers, Colors.green),
      ),
    ),
  ],
),

        const SizedBox(height: 20),

        Row(
  children: [
    Icon(
      Icons.show_chart,
      color: Theme.of(context).colorScheme.primary,
    ),
    const SizedBox(width: 8),
    Text(
      "User Growth",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    ),
  ],
),
const SizedBox(height: 6),
Divider(
  color: Theme.of(context).dividerColor,
  thickness: 1,
),

        const SizedBox(height: 20),

        /// 📊 GRAPH
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor, // ✅ FIXED
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, 1),
                    FlSpot(1, 3),
                    FlSpot(2, 2),
                    FlSpot(3, 5),
                    FlSpot(4, 4),
                    FlSpot(5, 6),
                    FlSpot(6, newUsers.toDouble()),
                  ],
                  isCurved: true,
                  color: Colors.redAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        /// 👥 RECENT USERS TITLE
        Row(
  children: [
    Icon(
      Icons.people,
      color: Theme.of(context).colorScheme.primary,
    ),
    const SizedBox(width: 8),
    Text(
      "Recent Users",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    ),
  ],
),
const SizedBox(height: 6),
Divider(
  color: Theme.of(context).dividerColor,
  thickness: 1,
),

        const SizedBox(height: 10),

        /// 👥 USER LIST
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No users found");
            }

            final users = snapshot.data!.docs;

            return Column(
              children: users.map((doc) {
               final raw = doc.data();

if (raw == null) {
  return const SizedBox.shrink(); // or continue
}

final data = raw as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      data['email'] ?? "No Email",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      data['name'] ?? "No Name",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}
  /// 🔥 SWITCH SCREEN
  Widget _getBody() {
    if (_selectedIndex == 0) {
      return _dashboardView();
    } else if (_selectedIndex == 1) {
  return const UserManagementScreen();
} else if (_selectedIndex == 2) {
  return const AdminSkillsScreen(); // 🔥 NEW
} else {
  return const ReportsScreen();
}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
 backgroundColor: Theme.of(context).scaffoldBackgroundColor,

  appBar: AppBar(
    title: const Text("Admin Panel"),
backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  ),

  /// 🔥 ADD DRAWER HERE
  drawer: Drawer(
    backgroundColor: Colors.black,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        /// 🔥 ADMIN HEADER
        const UserAccountsDrawerHeader(
          decoration: BoxDecoration(color: Colors.black),
          accountName: Text("Admin",
              style: TextStyle(color: Colors.white)),
          accountEmail: Text("admin@skillbarter.com",
              style: TextStyle(color: Colors.white70)),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
        ),

        /// 📊 DASHBOARD
        ListTile(
          leading: const Icon(Icons.dashboard, color: Colors.white),
          title: const Text("Dashboard",
              style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 0);
          },
        ),

        /// 👥 USERS
        ListTile(
          leading: const Icon(Icons.people, color: Colors.white),
          title:
              const Text("Users", style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 1);
          },
        ),
        /// 🧠 SKILLS
ListTile(
  leading: const Icon(Icons.verified, color: Colors.white),
  title: const Text("Skills", style: TextStyle(color: Colors.white)),
  onTap: () {
    Navigator.pop(context);
    setState(() => _selectedIndex = 2); // ✅ correct
  },
),

        /// 📩 REPORTS
        ListTile(
          leading: const Icon(Icons.report, color: Colors.white),
          title:
              const Text("Reports", style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 3);
          },
        ),

        const Divider(color: Colors.white24),


SwitchListTile(
  title: const Text("Dark Mode"),
  value: themeProvider.isDarkMode,
  onChanged: (value) {
    themeProvider.toggleTheme(value);
  },
  secondary: const Icon(Icons.dark_mode),
),
        /// 🚪 LOGOUT
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text("Logout",
              style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            Navigator.pop(context);
            await FirebaseAuth.instance.signOut();

            Navigator.pushNamedAndRemoveUntil(
  context,
  '/role',
  (route) => false,
);
          },
        ),
      ],
    ),
  ),

      /// 🔥 SWITCH BODY
      body: _getBody(),

      /// 🔥 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabChange,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
  BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
  BottomNavigationBarItem(icon: Icon(Icons.verified), label: "Skills"), // 🔥 NEW
  BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
],
      ),
    );
  }
}