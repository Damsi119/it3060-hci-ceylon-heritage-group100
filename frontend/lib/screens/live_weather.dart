import 'package:flutter/material.dart';

import '../models/weather_forecast.dart';
import '../services/tourism_service.dart';
import '../widgets/tourism_bottom_nav.dart';

/// Loads weather data from the Spring Boot weather endpoint.
class LiveWeatherScreen extends StatefulWidget {
  const LiveWeatherScreen({super.key});
  @override
  State<LiveWeatherScreen> createState() => _LiveWeatherScreenState();
}

class _LiveWeatherScreenState extends State<LiveWeatherScreen> {
  WeatherForecast? _weather;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weather = await TourismService.instance.getWeather();
      if (mounted)
        setState(() {
          _weather = weather;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.chevron_left),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather & Forecast',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            'Galle, Sri Lanka',
            style: TextStyle(fontSize: 10, color: Color(0xFF68716D)),
          ),
        ],
      ),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load weather: $_error',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ],
              ),
            ),
          )
        : _content(_weather!),
    bottomNavigationBar: const TourismBottomNav(currentIndex: 2),
  );

  Widget _content(WeatherForecast weather) => ListView(
    padding: const EdgeInsets.fromLTRB(17, 9, 17, 22),
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EEE8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${weather.location}, ${weather.province}',
                style: const TextStyle(
                  fontSize: 10,
                  color: _brown,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wb_cloudy_outlined,
                  size: 42,
                  color: Color(0xFFE99236),
                ),
                const SizedBox(width: 13),
                Text(
                  '${weather.temperatureCelsius}\u00B0C',
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF252D29),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              weather.condition,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: _line),
            ),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Humidity',
                    value: '${weather.humidityPercent}%',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Wind',
                    value: '${weather.windKmh} km/h',
                  ),
                ),
                Expanded(
                  child: _Metric(label: 'UV Index', value: weather.uvIndex),
                ),
              ],
            ),
          ],
        ),
      ),
      if (weather.demoData)
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
            'Sample forecast data',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: Color(0xFF87918B)),
          ),
        ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EEE8),
          border: Border.all(color: _brown),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.explore_outlined, size: 20, color: _brown),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Great weather for walking! Enjoy your historical walk around the Galle Fort Ramparts.',
                style: TextStyle(fontSize: 10, height: 1.4, color: _brown),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      const Text(
        'Hourly Forecast',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 84,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < weather.hourly.length; i++)
              _HourCard(forecast: weather.hourly[i], selected: i == 0),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        '5-Day Forecast',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      for (final day in weather.fiveDay) _DayRow(forecast: day),
      const SizedBox(height: 8),
      const Text(
        'Weather data © Open-Meteo',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9, color: Color(0xFF68716D)),
      ),
    ],
  );
}

const _brown = Color(0xFF824A2B);
const _line = Color(0xFFE9E2DB);

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 9, color: Color(0xFF68716D)),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _HourCard extends StatelessWidget {
  const _HourCard({required this.forecast, this.selected = false});
  final HourlyForecast forecast;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    width: 61,
    margin: const EdgeInsets.only(right: 7),
    decoration: BoxDecoration(
      color: selected ? _brown : Colors.white,
      border: Border.all(color: selected ? _brown : _line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          forecast.time,
          style: TextStyle(
            fontSize: 9,
            color: selected ? Colors.white : const Color(0xFF4D5752),
          ),
        ),
        const SizedBox(height: 5),
        Icon(
          forecast.condition.toLowerCase().contains('rain')
              ? Icons.umbrella_outlined
              : Icons.wb_sunny_outlined,
          size: 16,
          color: selected ? Colors.white : const Color(0xFFE99236),
        ),
        const SizedBox(height: 3),
        Text(
          '${forecast.temperatureCelsius}\u00B0',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF252D29),
          ),
        ),
      ],
    ),
  );
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.forecast});
  final DailyForecast forecast;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            forecast.day,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        Icon(
          forecast.condition.toLowerCase().contains('rain')
              ? Icons.umbrella_outlined
              : Icons.wb_sunny_outlined,
          size: 15,
          color: const Color(0xFFE99236),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            forecast.condition,
            style: const TextStyle(fontSize: 9, color: Color(0xFF68716D)),
          ),
        ),
        Text(
          '${forecast.highCelsius}\u00B0',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 9),
        Text(
          '${forecast.lowCelsius}\u00B0',
          style: const TextStyle(fontSize: 9, color: Color(0xFF68716D)),
        ),
      ],
    ),
  );
}
