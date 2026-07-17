import 'package:flutter/material.dart';

import '../models/bpr_profile_model.dart';
import '../services/bpr_service.dart';

class BprPickerField extends StatefulWidget {
  final bool enabled;
  final String? initialBprId;
  final ValueChanged<BprProfile?> onChanged;

  const BprPickerField({
    super.key,
    required this.onChanged,
    this.enabled = true,
    this.initialBprId,
  });

  @override
  State<BprPickerField> createState() => _BprPickerFieldState();
}

class _BprPickerFieldState extends State<BprPickerField> {
  final BprService _bprService = BprService();

  List<BprProfile> _options = const [];
  BprProfile? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final profiles = await _bprService.getActiveBprProfiles();
      if (!mounted) return;

      BprProfile? selected;
      final initialBprId = widget.initialBprId?.trim() ?? '';
      if (initialBprId.isNotEmpty) {
        for (final profile in profiles) {
          if (profile.bprId == initialBprId) {
            selected = profile;
            break;
          }
        }
      }
      if (selected == null && profiles.length == 1) {
        selected = profiles.first;
      }
      setState(() {
        _options = profiles;
        _selected = selected;
        _loading = false;
        _error = profiles.isEmpty
            ? 'Belum ada BPR aktif yang tersedia.'
            : null;
      });
      widget.onChanged(selected);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      setState(() {
        _options = const [];
        _selected = null;
        _loading = false;
        _error = raw.startsWith('Exception: ')
            ? raw.substring('Exception: '.length)
            : raw;
      });
      widget.onChanged(null);
    }
  }

  Future<void> _openPicker() async {
    if (!widget.enabled || _loading) return;

    if (_error != null || _options.isEmpty) {
      await _load();
      return;
    }

    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<BprProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BprPickerSheet(
        profiles: _options,
        selectedBprId: _selected?.bprId,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selected = selected);
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget suffix;
    if (_loading) {
      suffix = const Padding(
        padding: EdgeInsets.all(13),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_error != null) {
      suffix = const Icon(Icons.refresh, size: 21);
    } else {
      suffix = const Icon(Icons.arrow_drop_down, size: 24);
    }

    return InkWell(
      onTap: _openPicker,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        isEmpty: _selected == null,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.account_balance, size: 20),
          suffixIcon: suffix,
          errorText: _error,
          enabled: widget.enabled,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: _selected == null
            ? Text(
                _loading ? 'Memuat daftar BPR...' : 'Pilih nama BPR',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selected!.namaBpr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BPR ID: ${_selected!.bprId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BprPickerSheet extends StatefulWidget {
  final List<BprProfile> profiles;
  final String? selectedBprId;

  const _BprPickerSheet({
    required this.profiles,
    required this.selectedBprId,
  });

  @override
  State<_BprPickerSheet> createState() => _BprPickerSheetState();
}

class _BprPickerSheetState extends State<_BprPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<BprProfile> _filteredProfiles;

  @override
  void initState() {
    super.initState();
    _filteredProfiles = widget.profiles;
    _searchController.addListener(_filter);
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProfiles = widget.profiles;
        return;
      }

      _filteredProfiles = widget.profiles.where((profile) {
        return profile.namaBpr.toLowerCase().contains(query) ||
            profile.bprId.toLowerCase().contains(query) ||
            profile.alamat.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filter)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: screenHeight * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pilih BPR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0F3D2E),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari nama BPR atau BPR ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredProfiles.isEmpty
                    ? const Center(child: Text('BPR tidak ditemukan'))
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: _filteredProfiles.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final profile = _filteredProfiles[index];
                          final selected =
                              profile.bprId == widget.selectedBprId;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xff0F3D2E)
                                  .withOpacity(0.10),
                              child: const Icon(
                                Icons.account_balance,
                                color: Color(0xff0F3D2E),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              profile.namaBpr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Text(
                                  'BPR ID: ${profile.bprId}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (profile.alamat.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.alamat.replaceAll('\n', ' '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xff0F3D2E),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, profile),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
