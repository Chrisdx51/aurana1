import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final supabase = Supabase.instance.client;
  final SupabaseService supabaseService = SupabaseService();

  bool isLoading = true;
  String currentRole = '';
  int _currentIndex = 0;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _loadAdminData();
  }

  Future<void> _checkAdminRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    currentRole = profile['role'] ?? 'user';
    if (currentRole == 'user') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ You are not authorized to view this page.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _loadAdminData() async {
    setState(() => isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final user = await supabase.from('profiles').select('role').eq('id', userId).single();
      final userRole = user['role'];

      if (userRole == 'superadmin') {
        users = await supabaseService.getAllUsers();
        reports = await _fetchReports();
        notifications = await _fetchNotifications();
        logs = await _fetchLogs();

        await logAdminAction(
          adminId: userId,
          actionType: 'Load Admin Data',
          targetId: userId,
          targetTable: 'admin_panel',
          description: 'Superadmin loaded admin panel data.',
        );
      } else {
        users = await supabaseService.getLimitedUsers();
        reports = await _fetchLimitedReports();
        notifications = await _fetchLimitedNotifications();
        logs = [];
      }

      print("✅ Admin data loaded!");
    } catch (e) {
      print("❌ Error loading admin data: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await supabase.from('profiles').delete().eq('id', userId);
      _loadAdminData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ User deleted!')));
    } catch (e) {
      print("❌ Failed to delete user: $e");
    }
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await supabase.from('reports').delete().eq('id', reportId);
      _loadAdminData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Report deleted!')));
    } catch (e) {
      print("❌ Failed to delete report: $e");
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await supabase.from('notifications').delete().eq('id', notificationId);
      _loadAdminData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Notification deleted!')));
    } catch (e) {
      print("❌ Failed to delete notification: $e");
    }
  }

  Future<void> _deleteLog(String logId) async {
    try {
      await supabase.from('admin_logs').delete().eq('id', logId);
      _loadAdminData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Log deleted!')));
    } catch (e) {
      print("❌ Failed to delete log: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLimitedReports() async {
    try {
      final response = await supabase.from('reports').select('*').limit(10).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLimitedNotifications() async {
    try {
      final response = await supabase.from('notifications').select('*').limit(10).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final response = await supabase.from('reports').select('*').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final response = await supabase.from('notifications').select('*').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    final response = await supabase.from('admin_logs').select('*').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> logAdminAction({
    required String adminId,
    required String actionType,
    required String targetId,
    required String targetTable,
    required String description,
  }) async {
    try {
      await supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action_type': actionType,
        'target_id': targetId,
        'target_table': targetTable,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("❌ Error logging admin action: $e");
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      _loadAdminData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Role updated!')));
    } catch (e) {
      print("❌ Failed to update role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildUsersTab(),
      _buildReportsTab(),
      _buildNotificationsTab(),
      _buildLogsTab(),
      _buildAdsLogsTab(),
      _buildSoulMatchesLogsTab(),
      _buildFeedbackTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel 🛡️'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/profile.png', fit: BoxFit.cover)),
          isLoading ? Center(child: CircularProgressIndicator()) : pages[_currentIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black87,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Ads'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          color: Colors.white.withOpacity(0.9),
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            title: Text(user['name'] ?? 'Unknown'),
            subtitle: Text('Email: ${user['email'] ?? 'N/A'}\nRole: ${user['role'] ?? 'user'}'),
            trailing: currentRole == 'superadmin'
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.admin_panel_settings, color: Colors.black),
                  onSelected: (role) => _updateUserRole(user['id'], role),
                  itemBuilder: (context) => ['user', 'admin', 'limitedadmin', 'superadmin']
                      .map((role) => PopupMenuItem(value: role, child: Text(role)))
                      .toList(),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(user['id']),
                ),
              ],
            )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          color: Colors.white.withOpacity(0.9),
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text('Reason: ${report['reason'] ?? 'No reason'}'),
            subtitle: Text('Reported by: ${report['reporter_id'] ?? 'Unknown'}'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReport(report['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final note = notifications[index];
        return Card(
          color: Colors.white.withOpacity(0.9),
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(note['title'] ?? 'No Title'),
            subtitle: Text(note['body'] ?? 'No Body'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNotification(note['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    final filteredLogs = logs.where((log) => log['action_type'] != 'Load Admin Data').toList();

    return ListView.builder(
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return Card(
          color: Colors.white.withOpacity(0.9),
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(log['action_type'] ?? 'No Action'),
            subtitle: Text(
              'By Admin: ${log['admin_id']}\n'
                  'Target: ${log['target_id']}\n'
                  'Desc: ${log['description']}\n'
                  'At: ${log['created_at']}',
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdsLogsTab() {
    return FutureBuilder(
      future: supabase.from('service_ads').select('*').order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final ads = List<Map<String, dynamic>>.from(snapshot.data as List);
        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return Card(
              color: Colors.white.withOpacity(0.9),
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text(ad['business_name'] ?? 'Unknown Business'),
                subtitle: Text('Service: ${ad['service_type'] ?? ''}\nOwner: ${ad['user_id']}\nCreated: ${ad['created_at']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await supabase.from('service_ads').delete().eq('id', ad['id']);
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSoulMatchesLogsTab() {
    return FutureBuilder(
      future: supabase.from('soul_matches').select('*').order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final matches = List<Map<String, dynamic>>.from(snapshot.data as List);
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return Card(
              color: Colors.white.withOpacity(0.9),
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text('User: ${match['user_id']}'),
                subtitle: Text('Matched With: ${match['matched_user_id']}\nStatus: ${match['status']}\nCreated: ${match['created_at']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await supabase.from('soul_matches').delete().eq('id', match['id']);
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedbackTab() {
    return FutureBuilder(
      future: supabase.from('feedback').select('*').order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final feedbackList = List<Map<String, dynamic>>.from(snapshot.data as List);
        return ListView.builder(
          itemCount: feedbackList.length,
          itemBuilder: (context, index) {
            final feedback = feedbackList[index];
            return Card(
              color: Colors.white.withOpacity(0.9),
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text('User: ${feedback['user_id']}'),
                subtitle: Text('Message: ${feedback['message']}\nDate: ${feedback['created_at']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await supabase.from('feedback').delete().eq('id', feedback['id']);
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
