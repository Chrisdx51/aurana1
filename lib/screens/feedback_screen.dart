import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Bug';
  String _message = '';
  bool _isSubmitting = false;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ You must be logged in to submit feedback.')),
      );
      return;
    }

    try {
      await supabase.from('feedback').insert({
        'user_id': userId,
        'category': _category,
        'message': _message,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Feedback submitted! Thank you.')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to submit feedback.')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🟣 Custom AppBar with Aurana Colors
      appBar: AppBar(
        title: Text('Send Feedback 📝'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.deepPurple,
                Colors.redAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      // ✅ Wrap body to prevent overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟣 Category Dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontSize: 14),
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Bug',
                  'Suggestion',
                  'Love',
                  'Praise',
                  'Other',
                ].map((label) => DropdownMenuItem(
                  child: Text(label, style: TextStyle(fontSize: 14)),
                  value: label,
                )).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),

              SizedBox(height: 16),

              // 🟣 Message Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Your Message',
                  labelStyle: TextStyle(fontSize: 14),
                  hintText: 'Describe your thoughts...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please write a message'
                    : null,
                onChanged: (value) => _message = value,
              ),

              SizedBox(height: 24),

              // 🟣 Submit Button or Loader
              Center(
                child: _isSubmitting
                    ? CircularProgressIndicator() // 👈 this is your loader
                    : ElevatedButton.icon(
                  onPressed: _submitFeedback,
                  icon: Icon(Icons.send, color: Colors.white),
                  label: Text(
                    'Send',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.yellowAccent.withOpacity(0.8),
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Superman Red!
                    padding:
                    EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.yellowAccent.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}
