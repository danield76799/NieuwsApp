import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Since we don't have a utils/color_value.dart in NieuwsApp, we can either create it or avoid using hexValue.
// Let's create a simple extension on Color to get the hex value, or we can use the value directly.

// We'll create a simple extension for Color to get the hex value as an integer.
extension ColorExtension on Color {
  int get hexValue =>
      (a * 255).round() << 24 |
      (r * 255).round() << 16 |
      (g * 255).round() << 8 |
      (b * 255).round();
}

class ThemeBuilder extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    ThemeMode themeMode,
    Color? primaryColor,
    DynamicSchemeVariant schemeVariant,
    bool pureBlack,
    bool twemoji, // We might not use twemoji in NieuwsApp, but keep for consistency or remove.
  ) builder;

  final String themeModeSettingsKey;
  final String primaryColorSettingsKey;
  final String pureBlackSettingsKey;
  final String twemojiSettingsKey;
  final String schemeVariantSettingsKey;

  const ThemeBuilder({
    required this.builder,
    this.themeModeSettingsKey = 'com.danield.nieuwsapp.themeMode',
    this.primaryColorSettingsKey = 'com.danield.nieuwsapp.primaryColor',
    this.pureBlackSettingsKey = 'com.danield.nieuwsapp.pureBlack',
    this.twemojiSettingsKey = 'com.danield.nieuwsapp.twemojiFont',
    this.schemeVariantSettingsKey = 'com.danield.nieuwsapp.schemeVariant',
    super.key,
  });

  @override
  State<ThemeBuilder> createState() => _ThemeBuilderState();
}

class _ThemeBuilderState extends State<ThemeBuilder> {
  SharedPreferences? _sharedPreferences;
  ThemeMode? _themeMode;
  Color? _primaryColor;
  bool? _pureBlack;
  bool? _twemoji;
  DynamicSchemeVariant? _variant;

  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;

  Color? get primaryColor => _primaryColor;

  bool get pureBlack => _pureBlack ?? false;

  bool get twemoji => _twemoji ?? false;

  DynamicSchemeVariant get variant => _variant ?? DynamicSchemeVariant.tonalSpot;

  void _loadData(_) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();

    final rawThemeMode = preferences.getString(widget.themeModeSettingsKey);
    final rawColor = preferences.getInt(widget.primaryColorSettingsKey);
    final rawPureBlack = preferences.getBool(widget.pureBlackSettingsKey);
    final rawTwemoji = preferences.getBool(widget.twemojiSettingsKey);
    final rawVariant = preferences.getInt(widget.schemeVariantSettingsKey) ?? 
        DynamicSchemeVariant.values.indexOf(DynamicSchemeVariant.tonalSpot);

    if (!mounted) return;
    setState(() {
      _themeMode = ThemeMode.values.singleWhereOrNull(
        (value) => value.name == rawThemeMode,
      );
      _primaryColor = rawColor == null ? null : Color(rawColor);
      _pureBlack = rawPureBlack;
      _twemoji = rawTwemoji;
      _variant = DynamicSchemeVariant.values[rawVariant];
    });
  }

  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    await preferences.setString(widget.themeModeSettingsKey, newThemeMode.name);
    if (!mounted) return;
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  Future<void> setPrimaryColor(Color? newPrimaryColor) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    if (newPrimaryColor == null) {
      await preferences.remove(widget.primaryColorSettingsKey);
    } else {
      await preferences.setInt(
        widget.primaryColorSettingsKey,
        newPrimaryColor.hexValue,
      );
    }
    if (!mounted) return;
    setState(() {
      _primaryColor = newPrimaryColor;
    });
  }

  Future<void> setSchemeVariant(DynamicSchemeVariant? newVariant) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    if (newVariant == null) {
      await preferences.remove(widget.schemeVariantSettingsKey);
    } else {
      await preferences.setInt(
        widget.schemeVariantSettingsKey,
        DynamicSchemeVariant.values.indexOf(newVariant),
      );
    }
    if (!mounted) return;
    setState(() {
      _variant = newVariant;
    });
  }

  Future<void> setPureBlack(bool newPureBlack) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    await preferences.setBool(widget.pureBlackSettingsKey, newPureBlack);
    if (!mounted) return;
    setState(() {
      _pureBlack = newPureBlack;
    });
  }

  Future<void> setTwemoji(bool newTwemoji) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    await preferences.setBool(widget.twemojiSettingsKey, newTwemoji);
    if (!mounted) return;
    setState(() {
      _twemoji = newTwemoji;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_loadData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) => widget.builder(
          context,
          themeMode,
          // Use the dynamic color if available, otherwise fallback to the stored primaryColor or the default from the theme.
          primaryColor ?? 
              (themeMode == ThemeMode.light ? lightDynamic?.primary : darkDynamic?.primary),
          variant,
          pureBlack,
          twemoji,
        ),
      ),
    );
  }
}