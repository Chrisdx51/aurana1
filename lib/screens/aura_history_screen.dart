import 'dart:io';
import 'package:flutter/material.dart';
import 'aura_detail_screen.dart'; // Import the new detail screen
import '../database/aura_database_helper.dart';

class AuraHistoryScreen extends StatelessWidget {
  const AuraHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura History'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: AuraDatabaseHelper().fetchAuraDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading history: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No aura history found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final aura = data[index];
                final auraPath = aura['imagePath'];
                final auraMeaning = aura['auraMeaning'];
                final timestamp = aura['timestamp'] ?? 'Unknown Date';
                final String colorString = aura['auraColor'] ?? '#000000';
                late Color auraColor;

                try {
                  auraColor = Color(
                    int.parse(colorString.replaceFirst('#', '0xFF')),
                  );
                } catch (e) {
                  auraColor = Colors.black; // Fallback color
                  print('Error parsing color: $e');
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        auraPath != null
                            ? Image.file(
                          File(auraPath),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.image_not_supported, size: 50),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: auraColor,
                        ),
                      ],
                    ),
                    title: Text(
                      auraMeaning ?? 'Unknown Meaning',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Saved on: $timestamp'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await AuraDatabaseHelper().deleteAuraDetail(aura['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aura entry deleted.')),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuraDetailScreen(
                            imagePath: auraPath ?? '',
                            auraMeaning: auraMeaning ?? 'Unknown Meaning',
                            auraColor: auraColor,
                            timestamp: timestamp,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                'Unexpected error occurred.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }
}
