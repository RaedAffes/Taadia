class FormulaConfig {
  final String expression;

  FormulaConfig({this.expression = 'mahalia'});

  factory FormulaConfig.fromJson(String json) {
    if (json == 'mahalia' || json == 'jihawiya') {
      return FormulaConfig(expression: json);
    }
    return FormulaConfig(expression: 'mahalia');
  }

  String toJson() => expression;

  String displayLabel(String ichaaratLabel, String taalakinLabel) {
    return expression == 'jihawiya' ? 'جهوية (Jihawiya)' : 'محلية (Mahalia)';
  }
}
