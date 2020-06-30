import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'model_geiger_data.dart';

class CpmChartWidget extends StatelessWidget {
  final List<CpmDatum> cpmList;
  final bool animate;

  CpmChartWidget(this.cpmList, {this.animate});

  List<charts.Series<CpmDatum, DateTime>> seriesFromList(List<CpmDatum> myCpmList) {
    return [
      charts.Series<CpmDatum, DateTime>(
        id: 'cpm',
        colorFn: (CpmDatum gd, _) => charts.MaterialPalette.teal.shadeDefault,
        domainFn: (CpmDatum gd, _) => gd.timestamp,
        measureFn: (CpmDatum gd, _) => gd.avgCpm,
        measureLowerBoundFn: (CpmDatum gd, _) => (gd.minCpm ?? 0) > 0 ? gd.minCpm : gd.avgCpm,
        measureUpperBoundFn: (CpmDatum gd, _) => (gd.maxCpm ?? 0) > 0 ? gd.maxCpm : gd.avgCpm,
        data: myCpmList,
        // domainFormatterFn: (GeigerDatum cpmList, __) => ((ts) => '${ts.hour}:${ts.minute}'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesFromList(cpmList),
      animate: animate,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }
}
