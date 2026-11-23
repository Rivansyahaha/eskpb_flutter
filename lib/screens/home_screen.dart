import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/home_data.dart';
import '../models/kelas.dart';
import '../models/queue_status.dart';
import '../providers/home_provider.dart';
import '../providers/queue_provider.dart';
import '../routes/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/safe_asset_image.dart';
import '../widgets/state_views.dart';
import '../widgets/status_pill.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    await Future.wait([
      context.read<HomeProvider>().load(force: force),
      context.read<QueueProvider>().load(force: force),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final queue = context.watch<QueueProvider>();

    Widget body;
    if (home.data == null && home.loading) {
      body = const LoadingView();
    } else if (home.data == null) {
      body = ErrorView(
        message: home.error ?? 'Data belum tersedia.',
        onRetry: () => _load(force: true),
      );
    } else {
      body = _HomeBody(
        data: home.data!,
        queue: queue.status,
        updatedAt: queue.updatedAt,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _HomeAppBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(force: true),
              child: body is _HomeBody
                  ? body
                  : LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: c.maxHeight, child: body),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFAFFFFFF), Color(0xF5EDFAFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A002E38),
            blurRadius: 16,
            spreadRadius: -5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SafeAssetImage(
            AppAssets.itsEmblem,
            width: 40,
            height: 40,
            fallback: const Icon(Icons.school_rounded,
                size: 34, color: AppColors.green700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('e-SKPB', style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text('Mata Kuliah Bersama ITS', style: AppTextStyles.caption),
              ],
            ),
          ),
          Material(
            color: AppColors.tealTint,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go(AppRoutes.profile),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.person_outline_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.data,
    required this.queue,
    required this.updatedAt,
  });

  final HomeData data;
  final QueueStatus? queue;
  final DateTime? updatedAt;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final next = data.nextClass(DateTime.now());
    final ip = data.profile.ipSemester;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // Ringkasan semester
        Container(
          color: AppColors.summaryBackground,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEMESTER ${data.semesterNama.toUpperCase()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.summaryLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                queue == null
                    ? '${_greeting()}, ${data.profile.namaSapaan}'
                    : 'Antrean aktif terdeteksi',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 8),
              Text(
                queue == null
                    ? 'Akses kelas Mata Kuliah Bersama untuk seluruh mahasiswa ITS.'
                    : 'Pantau nomor ${queue!.nomor} sebelum giliran dipanggil.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.summarySubtle,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Metric(label: 'SKS diambil', value: '${data.sksDiambil}'),
                  const SizedBox(width: 8),
                  _Metric(
                    label: 'IP semester',
                    value: ip == null ? '-' : ip.toStringAsFixed(2),
                  ),
                  const SizedBox(width: 8),
                  _Metric(
                    label: 'Antrean aktif',
                    value: queue == null ? '0' : '1',
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(onTap: () => context.go(AppRoutes.quota)),
              const SizedBox(height: 12),
              _ActiveQueueCard(queue: queue, updatedAt: updatedAt),
              const SizedBox(height: 12),
              Text('Layanan utama', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.grid_view_rounded,
                      tint: AppColors.quotaIconTint,
                      color: AppColors.info,
                      title: 'Cek Kuota',
                      subtitle: 'Data real-time',
                      onTap: () => context.go(AppRoutes.quota),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.check_circle_outline_rounded,
                      tint: AppColors.validateIconTint,
                      color: AppColors.success,
                      title: 'Validasi',
                      subtitle: 'Cek kelayakan',
                      onTap: () => context.go(AppRoutes.quota),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.schedule_rounded,
                      tint: AppColors.queueIconTint,
                      color: AppColors.queueText,
                      title: 'Antrean',
                      subtitle: 'Nomor digital',
                      onTap: () => context.go(AppRoutes.queue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NextClassCard(kelasData: next),
              const SizedBox(height: 12),
              _InsightCard(data: data),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.summaryTile,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.metric),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.micro.copyWith(
                color: const Color(0xFFBFE5E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.r14,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Cari Mata Kuliah Bersama atau nomor kelas',
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, size: 18, color: AppColors.green700),
        ],
      ),
    );
  }
}

class _ActiveQueueCard extends StatelessWidget {
  const _ActiveQueueCard({required this.queue, required this.updatedAt});

  final QueueStatus? queue;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final q = queue;
    if (q == null) {
      return AppCard(
        onTap: () => context.go(AppRoutes.quota),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tealTint,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: const Icon(Icons.confirmation_number_outlined,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belum ada antrean aktif', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 3),
                  Text(
                    'Cek kuota, validasi kelas, lalu ambil nomor antrean.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      onTap: () => context.go(AppRoutes.queue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const InfoPill(
                text: 'ANTREAN AKTIF',
                background: AppColors.queueTint,
                foreground: AppColors.queueText,
              ),
              const Spacer(),
              if (updatedAt != null)
                Text(
                  'Diperbarui ${updatedAt!.hour.toString().padLeft(2, '0')}.${updatedAt!.minute.toString().padLeft(2, '0')} WIB',
                  style: AppTextStyles.micro,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.nomor, style: AppTextStyles.display),
                    const SizedBox(height: 1),
                    Text(
                      '${q.judulKelas} • ${q.sedangDilayani} dari ${q.urutan}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              InfoPill(text: '± ${q.estimasiMenit} menit'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.tint,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            Text(title, style: AppTextStyles.bodyBold),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.micro),
          ],
        ),
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.kelasData});

  final Kelas? kelasData;

  @override
  Widget build(BuildContext context) {
    final k = kelasData;
    if (k == null) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kelas berikutnya',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Belum ada kelas di KRS', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text(
              'Kelas yang sudah kamu ambil akan tampil di sini.',
              style: AppTextStyles.micro,
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Kelas berikutnya',
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              InfoPill(text: k.hariLabel.toUpperCase()),
            ],
          ),
          const SizedBox(height: 8),
          Text(k.judul, style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            [
              k.rentangJam,
              if (k.lokasi.isNotEmpty) k.lokasi,
              if (k.dosen != null) k.dosen!,
            ].join('  •  '),
            style: AppTextStyles.micro,
          ),
        ],
      ),
    );
  }
}

/// Kartu "Ringkasan Semester" di bawah Beranda.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final n = data.krs.length;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 142),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r20),
        gradient: AppGradients.insight,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E002E3B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 160,
            child: SafeAssetImage(
              AppAssets.campus,
              fit: BoxFit.cover,
              fallback: const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 150, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RINGKASAN SEMESTER',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFA1DEE0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.adaBentrok
                      ? 'Ada jadwal yang bertabrakan'
                      : 'Jadwalmu tetap terkendali',
                  style: AppTextStyles.title
                      .copyWith(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  data.adaBentrok
                      ? 'Periksa kelas di KRS-mu.'
                      : 'Tidak ada bentrok jadwal.',
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFFC7E8EB)),
                ),
                Text(
                  '$n kelas lintas departemen aktif.',
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFFC7E8EB)),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showSchedule(context, data),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat kalender',
                            style: AppTextStyles.captionBold
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showSchedule(BuildContext context, HomeData data) {
  final sorted = [...data.krs]..sort((a, b) {
      final d = a.hariIndex.compareTo(b.hariIndex);
      return d != 0 ? d : a.mulaiMenit.compareTo(b.mulaiMenit);
    });
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jadwal kelasmu', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(data.semesterNama, style: AppTextStyles.caption),
              const SizedBox(height: 14),
              if (sorted.isEmpty)
                const EmptyView(
                  icon: Icons.event_busy_outlined,
                  title: 'Belum ada kelas',
                  message: 'Kelas yang sudah kamu ambil akan tampil di sini.',
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final k in sorted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: InfoPill(text: k.hariLabel.toUpperCase()),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(k.judul, style: AppTextStyles.bodyBold),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${k.rentangJam}${k.lokasi.isEmpty ? '' : '  •  ${k.lokasi}'}',
                                      style: AppTextStyles.micro,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
  );
}
