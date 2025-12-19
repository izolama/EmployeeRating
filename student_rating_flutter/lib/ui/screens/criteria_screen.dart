import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/criteria.dart';
import '../../data/services/criteria_service.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_surface.dart';

class CriteriaScreen extends StatefulWidget {
  const CriteriaScreen({super.key});

  @override
  State<CriteriaScreen> createState() => CriteriaScreenState();
}

class CriteriaScreenState extends State<CriteriaScreen> {
  late final CriteriaService _service;
  late Future<List<Criteria>> _future;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = CriteriaService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _future = _service.fetchCriteria();
    });
    try {
      await _future;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> reload() => _load();

  Future<void> _showAddDialog() async {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'core');
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tambah Kriteria',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: 'Kode (contoh: K1)'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Kode wajib diisi' : null,
                ),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
                TextFormField(
                  controller: amountCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nilai Target (angka)'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nilai target wajib diisi' : null,
                ),
                DropdownButtonFormField<String>(
                  value: descCtrl.text,
                  items: const [
                    DropdownMenuItem(value: 'core', child: Text('Core')),
                    DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
                  ],
                  onChanged: (v) => descCtrl.text = v ?? 'core',
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await _service.upsertCriteria(
                      Criteria(
                        id: idCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        amount: int.parse(amountCtrl.text),
                        desc: descCtrl.text,
                      ),
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Criteria>>(
        future: _future,
        builder: (context, snapshot) {
          final isLoading = _isLoading ||
              snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.active;
          if (isLoading) return const _CriteriaSkeleton();
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final criteria = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
            children: [
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: const Text(
                    'Persyaratan (Core/Secondary)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ),
              ),
              ...criteria.map(
                (c) => AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Text('${c.id} - ${c.name}'),
                    subtitle: Text('Target: ${c.amount} | ${c.desc}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CriteriaSkeleton extends StatelessWidget {
  const _CriteriaSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
      children: [
        const ShimmerBlock(
          height: 86,
          radius: 18,
          margin: EdgeInsets.only(bottom: 12),
        ),
        ...List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppShimmer(
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0x33E7E7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      height: 16,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0x35F4F4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0x35F4F4FF),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0x2FF4F4FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
