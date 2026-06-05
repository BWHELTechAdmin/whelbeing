import 'package:flutter/material.dart';
import '../widgets/gold_shimmer.dart';
import '../utils/size_config.dart';

class CycleSettingsScreen extends StatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  double _cycleLength = 28;
  double _periodLength = 5;
  bool _trackFertility = true;
  bool _trackSymptoms = true;
  bool _trackMood = true;
  bool _periodReminder = true;
  bool _fertileReminder = false;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cycle Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle overview
            GoldShimmerContainer(
              borderRadius: BorderRadius.circular(4.0 * vw),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOverviewStat(
                    '${_cycleLength.round()}',
                    'Cycle Length',
                    'days',
                  ),
                  Container(
                    height: 4.7 * vh,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _buildOverviewStat(
                    '${_periodLength.round()}',
                    'Period Length',
                    'days',
                  ),
                  Container(
                    height: 4.7 * vh,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _buildOverviewStat(
                    '12',
                    'Cycles Tracked',
                    'total',
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Cycle Length',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 0.5 * vh),
            Text(
              'Average number of days in your cycle',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            SizedBox(height: 1.5 * vh),
            _buildSlider(
              value: _cycleLength,
              min: 20,
              max: 40,
              label: '${_cycleLength.round()} days',
              onChanged: (v) => setState(() => _cycleLength = v),
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Period Length',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 0.5 * vh),
            Text(
              'Average number of days your period lasts',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            SizedBox(height: 1.5 * vh),
            _buildSlider(
              value: _periodLength,
              min: 2,
              max: 10,
              label: '${_periodLength.round()} days',
              onChanged: (v) => setState(() => _periodLength = v),
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Tracking Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            _buildToggle(
              'Fertility Tracking',
              'Predict and track your fertile window',
              Icons.favorite_outline,
              _trackFertility,
              (v) => setState(() => _trackFertility = v),
            ),
            SizedBox(height: 1.0 * vh),
            _buildToggle(
              'Symptom Tracking',
              'Log physical symptoms throughout your cycle',
              Icons.healing,
              _trackSymptoms,
              (v) => setState(() => _trackSymptoms = v),
            ),
            SizedBox(height: 1.0 * vh),
            _buildToggle(
              'Mood Tracking',
              'Track emotional patterns across your cycle',
              Icons.mood,
              _trackMood,
              (v) => setState(() => _trackMood = v),
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Reminders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            _buildToggle(
              'Period Reminder',
              'Get notified 2 days before your predicted period',
              Icons.notifications_outlined,
              _periodReminder,
              (v) => setState(() => _periodReminder = v),
            ),
            SizedBox(height: 1.0 * vh),
            _buildToggle(
              'Fertile Window Reminder',
              'Get notified when your fertile window begins',
              Icons.notification_important_outlined,
              _fertileReminder,
              (v) => setState(() => _fertileReminder = v),
            ),
            SizedBox(height: 2.8 * vh),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label, String unit) {
    final vh = SizeConfig.vh;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 0.25 * vh),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 1.0 * vh),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: Row(
        children: [
          Text(
            '${min.round()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFC9A96E),
                inactiveTrackColor: const Color(0xFF2A2520),
                thumbColor: const Color(0xFFE8DCC8),
                overlayColor: const Color(0xFFC9A96E).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).round(),
                label: label,
                onChanged: onChanged,
              ),
            ),
          ),
          Text(
            '${max.round()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          SizedBox(width: 3.0 * vw),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 0.7 * vh),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A96E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2.0 * vw),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 0.25 * vh),
        secondary: Container(
          padding: EdgeInsets.all(2.0 * vw),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2520).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2.0 * vw),
          ),
          child: Icon(icon, color: const Color(0xFFE8DCC8), size: 5.0 * vw),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8DCC8),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        value: value,
        activeThumbColor: const Color(0xFFC9A96E),
        onChanged: onChanged,
      ),
    );
  }
}
