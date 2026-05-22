import 'dart:async';
import 'package:flutter/material.dart';

import 'custom_line_painter.dart';
import 'metrics_grid_card.dart';

void main() {
  runApp(const CropGuardApp());
}

class CropGuardApp extends StatelessWidget {
  const CropGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentTabIndex = 0;

  // --- CORE STATE REPOSITORY ---
  double currentUV = 8.4;
  int currentTemp = 34;
  int currentHumidity = 62;
  double alertThreshold = 6.0;
  bool notificationsEnabled = true;
  bool buzzerEnabled = true;
  double dailyUVDose = 18.2;
  double peakUV = 9.1;
  int alertsSentCount = 3;
  bool _isSimulatorExpanded = true;
  String selectedTimeframe = "24h";

  List<Map<String, String>> alertLogs = [
    {
      "id": "1",
      "time": "11:30 AM",
      "day": "TODAY",
      "title": "Extreme UV Detected",
      "desc": "UV index reached 9.1 - very high risk for crops. Cover plants immediately.",
      "badge": "CRITICAL"
    },
    {
      "id": "2",
      "time": "09:15 AM",
      "day": "TODAY",
      "title": "High UV Warning",
      "desc": "UV index at 7.0 exceeds safe crop threshold. Monitor closely.",
      "badge": "WARNING"
    },
    {
      "id": "3",
      "time": "07:45 AM",
      "day": "TODAY",
      "title": "UV Rising Fast",
      "desc": "UV index jumped sharply from 4.3 to 6.5 within a single data refresh window.",
      "badge": "WARNING"
    }
  ];

  Color getUVColor(double uv) {
    if (uv <= 2.9) return const Color(0xFF10B981);
    if (uv <= 5.9) return const Color(0xFFFBBF24);
    if (uv <= 7.9) return const Color(0xFFF97316);
    if (uv <= 10.9) return const Color(0xFFEF4444);
    return const Color(0xFF8B5CF6);
  }

  String getUVLabel(double uv) {
    if (uv <= 2.9) return "LOW - SAFE";
    if (uv <= 5.9) return "MODERATE MONITOR";
    if (uv <= 7.9) return "HIGH RISK";
    if (uv <= 10.9) return "VERY HIGH";
    return "EXTREME DANGER";
  }

  void updateUVValue(double newValue) {
    setState(() {
      currentUV = double.parse(newValue.toStringAsFixed(1));
      if (currentUV > peakUV) peakUV = currentUV;

      if (currentUV > alertThreshold) {
        bool logExists = alertLogs.any((e) => e["title"] == "Threshold Breach Simulated" && e["day"] == "TODAY");
        if (!logExists) {
          alertsSentCount++;
          alertLogs.insert(0, {
            "id": DateTime.now().millisecondsSinceEpoch.toString(),
            "time": "Just Now",
            "day": "TODAY",
            "title": "Threshold Breach Simulated",
            "desc": "Live field node reading of $currentUV crossed your active threshold limit ($alertThreshold).",
            "badge": "CRITICAL"
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isThresholdBreached = currentUV > alertThreshold;

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CropGuard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Field Node Online • Last Update: 1s ago', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            )
          ],
        ),
        backgroundColor: const Color(0xFF1B4332),
        elevation: 4,
      ),
      body: Column(
        children: [
          if (isThresholdBreached)
            Container(
              width: double.infinity,
              color: buzzerEnabled ? const Color(0xFFEF4444) : const Color(0xFFF97316),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buzzerEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    buzzerEnabled ? "🚨 HARDWARE BUZZER SOUNDING ON-SITE" : "⚠️ THRESHOLD EXCEEDED (Buzzer Suppressed)",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildHomeTab(isThresholdBreached),
                _buildMonitorTab(),
                _buildControlTab(),
              ],
            ),
          ),
          _buildHardwareSimulatorPanel(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Monitor'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Control'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(bool isBreached) {
    Color currentThemeColor = getUVColor(currentUV);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: currentThemeColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: currentThemeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              const Text('LIVE FIELD UV RADIATION INDEX', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 12),
              Text('$currentUV', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                child: Text(getUVLabel(currentUV), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isBreached ? const Color(0xFFFFE4E6) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isBreached ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alert Communication Relay Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isBreached ? const Color(0xFFEF4444) : const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                child: Text(isBreached ? "SENT / Notified" : "SAFE / Clear", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Secondary Crop Microclimate Telemetry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            MetricsGridCard(label: 'Temperature', value: '$currentTemp°C', subText: currentTemp > 32 ? 'Above avg' : 'Normal', accentColor: currentTemp > 32 ? Colors.orange : Colors.blue, icon: Icons.thermostat),
            MetricsGridCard(label: 'Humidity Rate', value: '$currentHumidity%', subText: 'Optimal Range', accentColor: Colors.teal, icon: Icons.water_drop),
            MetricsGridCard(label: 'UV Dose Accumulation', value: '$dailyUVDose kJ/m²', subText: 'Daily Total', accentColor: Colors.purple, icon: Icons.wb_sunny),
            MetricsGridCard(label: 'System Counters', value: 'Peak: $peakUV', subText: 'Alerts Fired: $alertsSentCount', accentColor: Colors.indigo, icon: Icons.analytics),
          ],
        ),
      ],
    );
  }

  Widget _buildMonitorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('On-Field Environmental Curves', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
            Row(
              children: [
                _buildTimeframeChip("24h"),
                const SizedBox(width: 6),
                _buildTimeframeChip("7d"),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildChartFrame("UV RADIATION TIMELINE CURVE (Index/Time)", CustomLinePainter(points: selectedTimeframe == "24h" ? [1.2, 2.5, 4.8, 6.5, currentUV, currentUV * 0.8] : [4.1, 5.2, 6.8, 8.1, 9.1, 7.3, currentUV], color: getUVColor(currentUV))),
        const SizedBox(height: 16),
        _buildChartFrame("AMBIENT TEMPERATURE HISTORY (Celsius)", CustomLinePainter(points: selectedTimeframe == "24h" ? [28.0, 30.0, 32.0, currentTemp.toDouble(), currentTemp - 2.0] : [29.0, 31.0, 33.0, 34.0, 32.0, 30.0, currentTemp.toDouble()], color: Colors.orange)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric("Peak Radiation", "$peakUV UV"),
              Container(width: 1, height: 30, color: Colors.grey),
              _buildStatMetric("Total Incident Logs", "$alertsSentCount Events"),
              Container(width: 1, height: 30, color: Colors.grey),
              _buildStatMetric("Mean Temp Tracking", "31.2 °C"),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimeframeChip(String label) {
    bool isSelected = selectedTimeframe == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) { if (val) setState(() => selectedTimeframe = label); },
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildChartFrame(String title, CustomPainter painter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 130, child: CustomPaint(painter: painter)),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildControlTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Remote Safety Configurations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Push App Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(notificationsEnabled ? 'Active' : 'Muted', style: const TextStyle(fontSize: 12)),
                value: notificationsEnabled,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => notificationsEnabled = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('On-Field Local Audio Buzzer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(buzzerEnabled ? 'Wired/Armed' : 'Hardware Disarmed', style: const TextStyle(fontSize: 12)),
                value: buzzerEnabled,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => buzzerEnabled = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('UV Threat Alert Threshold Boundary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('$alertThreshold UV', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: alertThreshold,
                min: 1.0,
                max: 12.0,
                divisions: 110,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => alertThreshold = double.parse(val.toStringAsFixed(1))),
              ),
              const Text('The local horn sound and cloud telemetry alerts will immediately dispatch once open field sensor scores exceed this setting.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3))
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Historical Alarm Dispatch Log (${alertLogs.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
            if (alertLogs.isNotEmpty)
              TextButton(onPressed: () => setState(() => alertLogs.clear()), child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 13)))
          ],
        ),
        const SizedBox(height: 8),
        if (alertLogs.isEmpty)
          Container(padding: const EdgeInsets.all(32), alignment: Alignment.center, child: const Text('No historical safety triggers logged.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alertLogs.length,
            itemBuilder: (context, index) {
              final log = alertLogs[index];
              Color badgeColor = log["badge"] == "CRITICAL" ? const Color(0xFFEF4444) : const Color(0xFFF97316);

              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                                child: Text(log["badge"]!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text(log["title"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            ],
                          ),
                          Text('${log["day"]} • ${log["time"]}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(log["desc"]!, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          onPressed: () { setState(() { alertLogs.removeAt(index); }); },
                          child: const Text('Dismiss', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHardwareSimulatorPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isSimulatorExpanded = !_isSimulatorExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.developer_board, color: Colors.lightBlueAccent, size: 18),
                      SizedBox(width: 8),
                      Text('IoT On-Field Hardware Telemetry Simulator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Icon(_isSimulatorExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white70)
                ],
              ),
            ),
          ),
          if (_isSimulatorExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildSimulatorSlider('UV Index Probe Reading:', currentUV, 0.0, 15.0, (val) => updateUVValue(val)),
                  _buildSimulatorSlider('Ambient Air Heat (°C):', currentTemp.toDouble(), 15.0, 50.0, (val) => setState(() => currentTemp = val.toInt())),
                  _buildSimulatorSlider('Relative Field Humidity (%):', currentHumidity.toDouble(), 10.0, 100.0, (val) => setState(() => currentHumidity = val.toInt())),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        setState(() {
                          currentTemp = 39;
                          currentHumidity = 31;
                          updateUVValue(11.8);
                        });
                      },
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Simulate Extreme Mid-Day Spike Threat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSimulatorSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70))),
          Expanded(
            flex: 5,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
              child: Slider(value: val, min: min, max: max, activeColor: Colors.lightBlueAccent, inactiveColor: Colors.white24, onChanged: onChanged),
            ),
          ),
          SizedBox(width: 35, child: Text(val.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 11)))
        ],
      ),
    );
  }
}
