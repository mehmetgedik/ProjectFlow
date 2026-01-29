import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/project.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/projectflow_logo_button.dart';
import 'work_package_detail_screen.dart';

/// Yeni iş paketi oluşturma ekranı. Proje, tip, başlık ve isteğe bağlı açıklama.
class CreateWorkPackageScreen extends StatefulWidget {
  const CreateWorkPackageScreen({super.key});

  @override
  State<CreateWorkPackageScreen> createState() => _CreateWorkPackageScreenState();
}

class _CreateWorkPackageScreenState extends State<CreateWorkPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Project> _projects = const [];
  List<Map<String, String>> _types = const [];
  Project? _selectedProject;
  String? _selectedTypeId;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  OpenProjectClient? _client(BuildContext context) => context.read<AuthState>().client;

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
      _types = const [];
      _selectedTypeId = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      _projects = await client.getProjects();
      final auth = context.read<AuthState>();
      if (_projects.isNotEmpty && auth.activeProject != null) {
        final match = _projects.where((p) => p.id == auth.activeProject!.id).toList();
        if (match.isNotEmpty) {
          _selectedProject = match.first;
          await _loadTypes(match.first.id);
        }
      }
    } catch (e) {
      setState(() {
        _error = ErrorMessages.userFriendly(e);
        _projects = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTypes(String projectId) async {
    setState(() => _selectedTypeId = null);
    try {
      final client = _client(context);
      if (client == null) return;
      _types = await client.getProjectTypes(projectId);
      if (_types.isNotEmpty && mounted) {
        setState(() => _selectedTypeId = _types.first['id']);
      }
    } catch (_) {
      if (mounted) setState(() => _types = const []);
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
      final wp = await client.createWorkPackage(
        projectId: project.id,
        typeId: typeId,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
    _loadProjects();
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
                          onPressed: _loadProjects,
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
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
                            border: OutlineInputBorder(),
                          ),
                          items: _projects
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name),
                                  ))
                              .toList(),
                          onChanged: (p) {
                            setState(() {
                              _selectedProject = p;
                              if (p != null) _loadTypes(p.id);
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
                              .map((t) => DropdownMenuItem(
                                    value: t['id'],
                                    child: Text(t['name'] ?? t['id']!),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedTypeId = v),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'İş tipi seçin.' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Başlık',
                            hintText: 'İş paketi başlığı',
                            border: OutlineInputBorder(),
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
                          decoration: const InputDecoration(
                            labelText: 'Açıklama (isteğe bağlı)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
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
                ),
    );
  }
}
