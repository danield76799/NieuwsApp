import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedArticleReaderScreen extends StatefulWidget {
  final String title;
  final String content;
  final String source;
  final DateTime pubDate;

  const CachedArticleReaderScreen({
    super.key,
    required this.title,
    required this.content,
    required this.source,
    required this.pubDate,
  });

  @override
  State<CachedArticleReaderScreen> createState() => _CachedArticleReaderScreenState();
}

class _CachedArticleReaderScreenState extends State<CachedArticleReaderScreen> {
  double _fontSize = 16.0;
  bool _showSlider = false;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 16.0;
    });
  }

  Future<void> _setFontSize(double size) async {
    setState(() => _fontSize = size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', size);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateString = DateFormat('d MMMM yyyy, HH:mm', 'nl_NL').format(widget.pubDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.source,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSlider ? Icons.text_fields : Icons.text_fields_outlined),
            tooltip: 'Lettertype grootte',
            onPressed: () => setState(() => _showSlider = !_showSlider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showSlider)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 12.0,
                        max: 28.0,
                        divisions: 16,
                        label: '${_fontSize.round()}',
                        onChanged: _setFontSize,
                      ),
                    ),
                    Icon(Icons.text_fields, size: 24, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source + date row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.source,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: theme.colorScheme.outlineVariant,
                      thickness: 1,
                    ),
                    const SizedBox(height: 20),
                    // Content
                    Text(
                      widget.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: _fontSize,
                        height: 1.7,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Footer
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.offline_bolt,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Offline gelezen',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
