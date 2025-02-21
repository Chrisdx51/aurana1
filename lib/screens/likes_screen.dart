import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikesScreen extends StatefulWidget {
  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> likes = [];

  @override
  void initState() {
    super.initState();
    fetchLikes();
  }

  Future<void> fetchLikes() async {
    final response = await supabase.from('likes').select('user_id, post_id');

    if (response.isNotEmpty) {
      setState(() {
        likes = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Likes')),
      body: likes.isEmpty
          ? Center(child: Text('No likes yet'))
          : ListView.builder(
        itemCount: likes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("User ${likes[index]['user_id']} liked Post ${likes[index]['post_id']}"),
          );
        },
      ),
    );
  }
}
