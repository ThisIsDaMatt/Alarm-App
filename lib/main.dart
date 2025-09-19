import 'package:flutter/material.dart';
import 'features/alarms/services/notification_service.dart';
import 'features/alarms/presentation/ring_screen.dart';
import 'features/alarms/presentation/alarm_controller.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/alarms/data/repositories/alarm_repository_hive.dart';
import 'features/alarms/domain/entities/alarm.dart';
import 'features/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = NotificationService();
  await notifications.init();
  await Hive.initFlutter();
  await AlarmRepositoryHive().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB));
    return ChangeNotifierProvider(
      create: (_) => AlarmController()..load(),
      child: MaterialApp(
        title: 'Alarm App',
        theme: ThemeData(useMaterial3: true, colorScheme: scheme),
        navigatorKey: NotificationService.navigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == '/ring') {
            return MaterialPageRoute(
              builder: (_) => RingScreen(payload: settings.arguments as String?),
              fullscreenDialog: true,
            );
          }
          return MaterialPageRoute(builder: (_) => const AlarmHomePage());
        },
        home: const AlarmHomePage(),
      ),
    );
  }
}

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({Key? key}) : super(key: key);

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<AlarmController>(
          builder: (context, c, _) {
            final alarms = c.alarms;
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 160,
                  title: const Text('Alarm App'),
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final t = ((constraints.maxHeight - kToolbarHeight) / (160 - kToolbarHeight)).clamp(0.0, 1.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.15 + 0.25 * t),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1 + 0.2 * t),
                            ],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Alarms',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Settings',
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                    ),
                  ],
                ),
                if (alarms.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onAdd: () => _openAddSheet(context)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    sliver: SliverList.builder(
                      itemCount: alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = alarms[index];
                        return _AlarmCard(
                          key: ValueKey(alarm.id),
                          alarm: alarm,
                          onToggle: (v) => c.updateAlarm(alarm.copyWith(isActive: v)),
                          onEdit: () => _openEditSheet(context, alarm),
                          onDelete: () async {
                            final removed = alarm;
                            await c.deleteAlarm(removed.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Alarm deleted'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () async {
                                    await c.addAlarm(removed.time, label: removed.label);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: _FAB(onPressed: (context) => _openAddSheet(context)),
      );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final alarm = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const AlarmEditorSheet(),
      ),
    );
    if (alarm != null) {
      await context.read<AlarmController>().addAlarm(alarm.time, label: alarm.label);
    }
  }

  Future<void> _openEditSheet(BuildContext context, Alarm existing) async {
    final updated = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AlarmEditorSheet(editAlarm: existing),
      ),
    );
    if (updated != null) {
      await context.read<AlarmController>().updateAlarm(updated);
    }
  }
}

class AlarmEditor extends StatefulWidget {
  final Alarm? editAlarm;
  const AlarmEditor({Key? key, this.editAlarm}) : super(key: key);

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late TimeOfDay _time;
  late TextEditingController _label;
  int _repeatDays = 0; // bitmask Sun=0..Sat=6
  int _snooze = 10;
  double _volume = 1.0;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _time = widget.editAlarm != null ? TimeOfDay(hour: widget.editAlarm!.time.hour, minute: widget.editAlarm!.time.minute) : now;
    _label = TextEditingController(text: widget.editAlarm?.label ?? '');
    if (widget.editAlarm != null) {
      _repeatDays = widget.editAlarm!.repeatDays;
      _snooze = widget.editAlarm!.snoozeMinutes;
      _volume = widget.editAlarm!.volume;
      _vibration = widget.editAlarm!.vibration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.editAlarm != null ? 'Edit Alarm' : 'Add Alarm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TimePicker(
              onPick: () async {
                final picked = await showTimePicker(context: context, initialTime: _time);
                if (picked != null) setState(() => _time = picked);
              },
              label: _time.format(context),
            ),
            TextField(
              key: const Key('timeField'),
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
            const SizedBox(height: 8),
            _DaysSelector(
              initial: _repeatDays,
              onChanged: (v) => setState(() => _repeatDays = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Snooze'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _snooze,
                  items: const [5, 10, 15, 20, 30]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                      .toList(),
                  onChanged: (v) => setState(() => _snooze = v ?? 10),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Volume'),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: (v) => setState(() => _volume = v),
                  ),
                ),
                Row(children: [const Text('Vibration'), Switch(value: _vibration, onChanged: (v) => setState(() => _vibration = v))]),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('saveButton'),
              onPressed: () {
                final now = DateTime.now();
                final dt = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
                final alarm = widget.editAlarm == null
                    ? Alarm(
                        id: UniqueKey().toString(),
                        time: dt,
                        isActive: true,
                        label: _label.text.isEmpty ? null : _label.text,
                        repeatDays: _repeatDays,
                        snoozeMinutes: _snooze,
                        volume: _volume,
                        vibration: _vibration,
                      )
                    : widget.editAlarm!.copyWith(
                        time: dt,
                        label: _label.text.isEmpty ? null : _label.text,
                        repeatDays: _repeatDays,
                        snoozeMinutes: _snooze,
                        volume: _volume,
                        vibration: _vibration,
                      );
                Navigator.of(context).pop(alarm);
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}

class TimePicker extends StatelessWidget {
  final VoidCallback? onPick;
  final String? label;
  const TimePicker({Key? key, this.onPick, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.4)),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label ?? 'Time Picker',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final m = time.minute.toString().padLeft(2, '0');
  final ampm = time.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

class AlarmEditorSheet extends StatelessWidget {
  final Alarm? editAlarm;
  const AlarmEditorSheet({super.key, this.editAlarm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AlarmEditor(editAlarm: editAlarm),
    );
  }
}

class _FAB extends StatelessWidget {
  final void Function(BuildContext) onPressed;
  const _FAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => onPressed(context),
      icon: const Icon(Icons.add),
      label: const Text('Add alarm'),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AlarmCard({super.key, required this.alarm, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final daysText = _daysSummary(alarm.repeatDays);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Dismissible(
        key: Key('dismiss_${alarm.id}'),
        background: _dismissBg(context, true),
        secondaryBackground: _dismissBg(context, false),
        onDismissed: (_) => onDelete(),
        child: Card(
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'time_${alarm.id}',
                          child: Text(
                            _formatTime(alarm.time),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (alarm.label != null) Text(alarm.label!, style: Theme.of(context).textTheme.bodyMedium),
                            if (alarm.label != null && daysText.isNotEmpty) const Text(' • '),
                            if (daysText.isNotEmpty)
                              Text(
                                daysText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(value: alarm.isActive, onChanged: onToggle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dismissBg(BuildContext context, bool left) {
    final color = Theme.of(context).colorScheme.errorContainer;
    return Container(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: color,
      child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
    );
  }

  String _daysSummary(int mask) {
    if (mask == 0) return '';
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selected = <String>[];
    for (int i = 0; i < 7; i++) {
      if ((mask & (1 << i)) != 0) selected.add(labels[i]);
    }
    if (selected.length == 7) return 'Every day';
    if (selected.length == 2 && selected.containsAll(['Sat', 'Sun'])) return 'Weekends';
    if (selected.length == 5 && !selected.contains('Sat') && !selected.contains('Sun')) return 'Weekdays';
    return selected.join(', ');
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm, size: 96, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No alarms yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first alarm and wake up with random voice lines.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add alarm')),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _svc = SettingsService();
  String _voiceMode = 'aggressive';
  bool _avoidRepeat = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _svc.getVoiceMode();
    final avoid = await _svc.getAvoidRepeat();
    setState(() {
      _voiceMode = mode;
      _avoidRepeat = avoid;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Voice mode'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'aggressive', label: Text('Aggressive'), icon: Icon(Icons.flash_on)),
              ButtonSegment(value: 'motivational', label: Text('Motivational'), icon: Icon(Icons.sentiment_satisfied)),
            ],
            selected: {_voiceMode},
            onSelectionChanged: (s) async {
              final v = s.first;
              setState(() => _voiceMode = v);
              await _svc.setVoiceMode(v);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _avoidRepeat,
            onChanged: (v) async {
              setState(() => _avoidRepeat = v);
              await _svc.setAvoidRepeat(v);
            },
            title: const Text('Avoid repeating last voice'),
            subtitle: const Text('Improves variety of wake-up lines'),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Permissions'),
            subtitle: const Text('Android: Notifications, Alarm; iOS: Alerts/Sounds/Badges'),
          ),
        ],
      ),
    );
  }
}


class _DaysSelector extends StatelessWidget {
  final int initial; // bitmask
  final ValueChanged<int> onChanged;
  const _DaysSelector({required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    int mask = initial;
    final dayLabels = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final bit = 1 << i;
        final selected = (mask & bit) != 0;
        return FilterChip(
          selected: selected,
          label: Text(dayLabels[i]),
          onSelected: (v) {
            mask = v ? (mask | bit) : (mask & ~bit);
            onChanged(mask);
          },
        );
      }),
    );
  }
}
