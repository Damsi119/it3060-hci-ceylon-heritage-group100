class WeatherForecast {
  const WeatherForecast({
    required this.location,
    required this.province,
    required this.temperatureCelsius,
    required this.condition,
    required this.humidityPercent,
    required this.windKmh,
    required this.uvIndex,
    required this.hourly,
    required this.fiveDay,
    required this.demoData,
  });

  final String location, province, condition, uvIndex;
  final int temperatureCelsius, humidityPercent, windKmh;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> fiveDay;
  final bool demoData;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
        location: json['location'] as String? ?? 'Galle',
        province: json['province'] as String? ?? '',
        temperatureCelsius: (json['temperatureCelsius'] as num?)?.toInt() ?? 0,
        condition: json['condition'] as String? ?? '',
        humidityPercent: (json['humidityPercent'] as num?)?.toInt() ?? 0,
        windKmh: (json['windKmh'] as num?)?.toInt() ?? 0,
        uvIndex: json['uvIndex'] as String? ?? '',
        hourly: (json['hourly'] as List<dynamic>? ?? const [])
            .map((item) => HourlyForecast.fromJson(item as Map<String, dynamic>))
            .toList(),
        fiveDay: (json['fiveDay'] as List<dynamic>? ?? const [])
            .map((item) => DailyForecast.fromJson(item as Map<String, dynamic>))
            .toList(),
        demoData: json['demoData'] as bool? ?? false,
      );
}

class HourlyForecast {
  const HourlyForecast(this.time, this.temperatureCelsius, this.condition);
  final String time, condition;
  final int temperatureCelsius;
  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
        json['time'] as String? ?? '',
        (json['temperatureCelsius'] as num?)?.toInt() ?? 0,
        json['condition'] as String? ?? '',
      );
}

class DailyForecast {
  const DailyForecast(this.day, this.highCelsius, this.lowCelsius, this.condition);
  final String day, condition;
  final int highCelsius, lowCelsius;
  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        json['day'] as String? ?? '',
        (json['highCelsius'] as num?)?.toInt() ?? 0,
        (json['lowCelsius'] as num?)?.toInt() ?? 0,
        json['condition'] as String? ?? '',
      );
}
