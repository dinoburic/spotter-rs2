
import 'package:Spotter_desktop/models/unit_of_measure.dart';
import 'package:Spotter_desktop/providers/base_provider.dart';



class UnitOfMeasureProvider extends BaseProvider<UnitOfMeasure> {
  UnitOfMeasureProvider() : super("UnitOfMeasures");

  @override
  UnitOfMeasure fromJson(data) {
    return UnitOfMeasure.fromJson(data);
  }
}