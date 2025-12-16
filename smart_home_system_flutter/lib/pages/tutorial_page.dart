import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import '../widgets/app_drawer.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial'),
        titleTextStyle: TextStyle(fontSize: controller.resolvedFontSize*1.5,),
        backgroundColor: controller.accentColor,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: EdgeInsetsGeometry.only(left: 36, right: 36, top: 36),
        children: [
          _buildVideoSection(),
          const SizedBox(height: 24),
          _buildFAQSection(),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tutorial Videos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, size: 64),
          ),
        ),
        const SizedBox(height: 8),
        Text('Getting Started with Floor Plan Editor'),
      ],
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          'How do I add a room to my floor plan?',
          'Drag and drop shapes from the top toolbar onto the canvas. The system will automatically find the nearest available position.',
        ),
        _buildFAQItem(
          'Can I move rooms after placing them?',
          'Yes! Simply click and drag any placed room to reposition it. The system will snap it to the nearest available grid position.',
        ),
        _buildFAQItem(
          'How do I connect devices?',
          'Go to the Devices page from the menu, click "Scan for Devices", and toggle the switches to connect/disconnect devices.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: TextStyle(fontSize: ThemeModeController().resolvedFontSize),),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}