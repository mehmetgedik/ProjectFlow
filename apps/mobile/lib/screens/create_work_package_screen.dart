import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/project.dart';
import '../models/version.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';
import 'work_package_detail_screen.dart';

/// Yeni iş paketi oluşturma ekranı. Web formundaki alanlar: proje, tip, başlık, açıklama,
/// atanan, öncelik, durum, üst iş, versiyon, başlangıç/bitiş tarihi. Sesle giriş aktif.
class CreateWorkPackageScreen extends StatefulWidget {
  const CreateWorkPackageScreen({super.key});

  @override
  State<CreateWorkPackageScreen> createState() => _CreateWorkPackageScreenState();
}

class _CreateWorkPackageScreenState extends State<CreateWorkPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _parentIdController = TextEditingController();
  final _subjectFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Project> _projects = const [];
  List<Map<String, String>> _types = const [];
  List<Map<String, String>> _statuses = const [];
  List<Map<String, String>> _priorities = const [];
  List<Map<String, String>> _members = const [];
  List<Version> _versions = const [];
  Project? _selectedProject;
  String? _selectedTypeId;
  String? _selectedStatusId;
  String? _selectedPriorityId;
  String? _selectedAssigneeId;
  String? _selectedVersionId;
  DateTime? _startDate;
  DateTime? _dueDate;

  OpenProjectClient? _client(BuildContext context) => context.read<AuthState>().client;

  /// Durum için renk ve ikon (iş detay ekranı ile tutarlı).
  (Color bg, Color fg, IconData icon) _statusVisuals(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.toLowerCase();
    if (s.contains('yeni') || s.contains('new')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.fiber_new_rounded);
    }
    if (s.contains('devam') || s.contains('progress') || s.contains('in progress')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.play_arrow_rounded);
    }
    if (s.contains('bekle') || s.contains('on hold') || s.contains('pending')) {
      return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.pause_circle_filled_rounded);
    }
    if (s.contains('tamam') || s.contains('closed') || s.contains('done') || s.contains('çözüldü')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.check_circle_rounded);
    }
    if (s.contains('iptal') || s.contains('cancel')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.cancel_rounded);
    }
    return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.adjust_rounded);
  }

  /// Öncelik için renk ve ikon.
  (Color bg, Color fg, IconData icon) _priorityVisuals(BuildContext context, String priority) {
    final theme = Theme.of(context);
    final p = (priority.isEmpty ? '' : priority).toLowerCase();
    if (p.contains('acil') || p.contains('urgent') || p.contains('yüksek') || p.contains('high') || p.contains('critical')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.priority_high_rounded);
    }
    if (p.contains('orta') || p.contains('medium') || p.contains('normal')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.remove_circle_outline_rounded);
    }
    if (p.contains('düşük') || p.contains('low')) {
      return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.low_priority_rounded);
    }
    return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.flag_rounded);
  }

  /// İş tipi için renk ve ikon.
  (Color bg, Color fg, IconData icon) _typeVisuals(BuildContext context, String type) {
    final theme = Theme.of(context);
    final t = type.toLowerCase();
    if (t.contains('bug') || t.contains('hata')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.bug_report_rounded);
    }
    if (t.contains('task') || t.contains('görev')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.checklist_rounded);
    }
    if (t.contains('feature') || t.contains('özellik')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.auto_awesome_rounded);
    }
    if (t.contains('milestone') || t.contains('kilometre')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.flag_rounded);
    }
    return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.label_rounded);
  }

  /// Atanan için avatar URL (instance API base + users/id/avatar).
  String? _avatarUrlForUser(AuthState auth, String userId) {
    final base = auth.instanceApiBaseUrl;
    if (base == null || base.isEmpty) return null;
    return '$base/users/$userId/avatar';
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _types = const [];
      _statuses = const [];
      _priorities = const [];
      _members = const [];
      _versions = const [];
      _selectedTypeId = null;
      _selectedStatusId = null;
      _selectedPriorityId = null;
      _selectedAssigneeId = null;
      _selectedVersionId = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      _projects = await client.getProjects();
      final statuses = await client.getStatuses();
      final priorities = await client.getPriorities();
      final auth = context.read<AuthState>();
      Project? preSelect;
      if (_projects.isNotEmpty && auth.activeProject != null) {
        final match = _projects.where((p) => p.id == auth.activeProject!.id).toList();
        if (match.isNotEmpty) preSelect = match.first;
      }
      if (preSelect != null) {
        _selectedProject = preSelect;
        await _loadProjectDependent(preSelect.id);
      }
      if (mounted) {
        setState(() {
          _statuses = statuses;
          _priorities = priorities;
          if (_types.isNotEmpty && _selectedTypeId == null) _selectedTypeId = _types.first['id'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessages.userFriendly(e);
          _projects = const [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadProjectDependent(String projectId) async {
    final client = _client(context);
    if (client == null) return;
    try {
      final types = await client.getProjectTypes(projectId);
      final members = await client.getProjectMembers(projectId);
      final versions = await client.getProjectVersions(projectId);
      if (mounted) {
        setState(() {
          _types = types;
          _members = members;
          _versions = versions;
          if (_types.isNotEmpty) _selectedTypeId = _types.first['id'];
          _selectedAssigneeId = null;
          _selectedVersionId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _types = const [];
          _members = const [];
          _versions = const [];
        });
      }
    }
  }

  void _showVoiceHint() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klavyede mikrofon ile sesli yazabilirsiniz.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_dueDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) _startDate = picked;
        else _dueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final project = _selectedProject;
    final typeId = _selectedTypeId;
    if (project == null || typeId == null || typeId.isEmpty) {
      setState(() => _error = 'Proje ve iş tipi seçin.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      final parentId = _parentIdController.text.trim();
      final wp = await client.createWorkPackage(
        projectId: project.id,
        typeId: typeId,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        assigneeId: _selectedAssigneeId?.isEmpty == true ? null : _selectedAssigneeId,
        priorityId: _selectedPriorityId?.isEmpty == true ? null : _selectedPriorityId,
        statusId: _selectedStatusId?.isEmpty == true ? null : _selectedStatusId,
        parentId: parentId.isEmpty ? null : parentId,
        versionId: _selectedVersionId?.isEmpty == true ? null : _selectedVersionId,
        startDate: _startDate,
        dueDate: _dueDate,
      );
      if (mounted) {
        mediumImpact();
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş paketi oluşturuldu.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WorkPackageDetailScreen(workPackage: wp),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ErrorMessages.userFriendly(e);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _parentIdController.dispose();
    _subjectFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni iş paketi'),
        actions: const [ProjectFlowLogoButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _projects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadInitial,
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final auth = context.watch<AuthState>();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<Project>(
                              value: _selectedProject,
                              decoration: const InputDecoration(
                                labelText: 'Proje',
                                prefixIcon: Icon(Icons.folder_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: _projects
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Row(
                                          children: [
                                            Icon(Icons.folder_rounded, size: 20, color: theme.colorScheme.primary),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(p.name)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (p) {
                                setState(() {
                                  _selectedProject = p;
                                  if (p != null) _loadProjectDependent(p.id);
                                });
                              },
                              validator: (v) => v == null ? 'Proje seçin.' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedTypeId,
                              decoration: const InputDecoration(
                                labelText: 'İş tipi',
                                border: OutlineInputBorder(),
                              ),
                              items: _types
                                  .map((t) {
                                    final name = t['name'] ?? t['id'] ?? '';
                                    final (bg, fg, icon) = _typeVisuals(context, name);
                                    return DropdownMenuItem<String>(
                                      value: t['id'],
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, size: 18, color: fg),
                                                const SizedBox(width: 6),
                                                Text(name, style: TextStyle(color: fg, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedTypeId = v),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'İş tipi seçin.' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subjectController,
                              focusNode: _subjectFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Başlık',
                                hintText: 'İş paketi başlığı',
                                prefixIcon: const Icon(Icons.title_rounded),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.mic_outlined),
                                  onPressed: () {
                                    _subjectFocusNode.requestFocus();
                                    _showVoiceHint();
                                  },
                                  tooltip: 'Sesle yazmak için alana odaklan',
                                ),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              maxLength: 255,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Başlık zorunlu.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              focusNode: _descriptionFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Açıklama (isteğe bağlı)',
                                prefixIcon: const Icon(Icons.notes_rounded),
                                border: const OutlineInputBorder(),
                                alignLabelWithHint: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.mic_outlined),
                                  onPressed: () {
                                    _descriptionFocusNode.requestFocus();
                                    _showVoiceHint();
                                  },
                                  tooltip: 'Sesle yazmak için alana odaklan',
                                ),
                              ),
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedAssigneeId == null || _selectedAssigneeId!.isEmpty
                                  ? null
                                  : _selectedAssigneeId,
                              decoration: const InputDecoration(
                                labelText: 'Atanan',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_off_outlined, size: 22, color: Colors.grey),
                                      SizedBox(width: 12),
                                      Text('— Atanmamış'),
                                    ],
                                  ),
                                ),
                                ..._members.map((m) {
                                  final id = m['id']!;
                                  final name = m['name'] ?? id;
                                  final avatarUrl = _avatarUrlForUser(auth, id);
                                  final headers = auth.authHeadersForInstanceImages;
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Row(
                                      children: [
                                        LetterAvatar(
                                          displayName: name,
                                          imageUrl: avatarUrl,
                                          imageHeaders: headers,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(name)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(() => _selectedAssigneeId = v),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedPriorityId,
                              decoration: const InputDecoration(
                                labelText: 'Öncelik',
                                border: OutlineInputBorder(),
                              ),
                              items: _priorities
                                  .map((p) {
                                    final name = p['name'] ?? p['id'] ?? '';
                                    final (bg, fg, icon) = _priorityVisuals(context, name);
                                    return DropdownMenuItem<String>(
                                      value: p['id'],
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, size: 18, color: fg),
                                                const SizedBox(width: 6),
                                                Text(name, style: TextStyle(color: fg, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedPriorityId = v),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedStatusId,
                              decoration: const InputDecoration(
                                labelText: 'Durum',
                                border: OutlineInputBorder(),
                              ),
                              items: _statuses
                                  .map((s) {
                                    final name = s['name'] ?? s['id'] ?? '';
                                    final (bg, fg, icon) = _statusVisuals(context, name);
                                    return DropdownMenuItem<String>(
                                      value: s['id'],
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, size: 18, color: fg),
                                                const SizedBox(width: 6),
                                                Text(name, style: TextStyle(color: fg, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedStatusId = v),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _parentIdController,
                              decoration: const InputDecoration(
                                labelText: 'Üst iş (ID)',
                                hintText: 'Üst iş paketi numarası (boş bırakılabilir)',
                                prefixIcon: Icon(Icons.account_tree_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            if (_versions.isNotEmpty)
                              DropdownButtonFormField<String>(
                                value: _selectedVersionId,
                                decoration: const InputDecoration(
                                  labelText: 'Versiyon / Sprint',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Icon(Icons.flag_outlined, size: 20, color: Colors.grey),
                                        SizedBox(width: 12),
                                        Text('— Seçiniz'),
                                      ],
                                    ),
                                  ),
                                  ..._versions.map((v) => DropdownMenuItem<String>(
                                        value: v.id.toString(),
                                        child: Row(
                                          children: [
                                            Icon(
                                              v.isOpen ? Icons.directions_run_rounded : Icons.flag_rounded,
                                              size: 20,
                                              color: v.isOpen ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text('${v.name}${v.isOpen ? ' (açık)' : ''}'),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                                onChanged: (v) => setState(() => _selectedVersionId = v),
                              ),
                            if (_versions.isNotEmpty) const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickDate(context, true),
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(
                                      _startDate != null
                                          ? '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}'
                                          : 'Başlangıç',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickDate(context, false),
                                    icon: const Icon(Icons.event, size: 18),
                                    label: Text(
                                      _dueDate != null
                                          ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'
                                          : 'Bitiş',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _saving ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Oluştur'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
