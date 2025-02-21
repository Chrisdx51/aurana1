import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RelationsScreen extends StatefulWidget {
  @override
  _RelationsScreenState createState() => _RelationsScreenState();
}

class _RelationsScreenState extends State<RelationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> relations = [];

  @override
  void initState() {
    super.initState();
    fetchRelations();
  }

  Future<void> fetchRelations() async {
    final response = await supabase.from('relations').select('*');

    if (response.isNotEmpty) {
      setState(() {
        relations = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relations')),
      body: relations.isEmpty
          ? Center(child: Text('No relations yet'))
          : ListView.builder(
        itemCount: relations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("User ${relations[index]['user_id']} is connected with ${relations[index]['friend_id']}"),
          );
        },
      ),
    );
  }
}
