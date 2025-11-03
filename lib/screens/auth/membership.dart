import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/providers/auth_provider.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({Key? key}) : super(key: key);

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseColor(String? value, {Color? fallback}) {
    if (value == null || value.isEmpty) return fallback ?? Colors.green;
    try {
      var str = value.trim().replaceAll('#', '').replaceAll('0x', '');
      if (str.length == 6) str = 'FF$str';
      return Color(int.parse(str, radix: 16));
    } catch (_) {
      return fallback ?? Colors.green;
    }
  }

  (Color, Color) _defaultColorsForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('platinum')) {
      return (const Color(0xFF8E2DE2), const Color(0xFF4A00E0));
    } else if (n.contains('gold')) {
      return (const Color(0xFFFFD700), const Color(0xFFFFC107));
    } else if (n.contains('silver')) {
      return (const Color(0xFFB0BEC5), const Color(0xFF90A4AE));
    } else if (n.contains('bronze')) {
      return (const Color(0xFFC0A080), const Color(0xFFB58E63));
    }
    return (const Color(0xFF22A45D), const Color(0xFF1C8E50));
  }

  Map<String, dynamic> _normalizeTier(dynamic raw) {
    if (raw is! Map) return {};

    String name = (raw['name'] ?? raw['title'] ?? raw['tier_name'] ?? 'Member')
        .toString();

    int minPts =
        (raw['min_points'] ??
                raw['minPoints'] ??
                raw['threshold_min'] ??
                raw['start_points'] ??
                0)
            as int;
    int maxPts =
        (raw['max_points'] ??
                raw['maxPoints'] ??
                raw['threshold_max'] ??
                raw['end_points'] ??
                999999)
            as int;

    String priceText =
        (raw['price_text'] ?? raw['price'] ?? raw['annual_price'] ?? '')
            .toString();

    String? c1 = (raw['color1'] ?? raw['primary_color'] ?? raw['color_code'])
        ?.toString();
    String? c2 = (raw['color2'] ?? raw['secondary_color'])?.toString();
    final (def1, def2) = _defaultColorsForName(name);
    final color1 = _parseColor(c1, fallback: def1);
    final color2 = _parseColor(c2, fallback: def2);

    final benefitsText =
        (raw['benefits'] ??
                raw['benefits_text'] ??
                (raw['perks'] is List ? (raw['perks'] as List).join(', ') : ''))
            .toString();

    return {
      'name': name,
      'price_text': priceText,
      'min_points': minPts,
      'max_points': maxPts,
      'color1': color1,
      'color2': color2,
      'benefits_text': benefitsText,
    };
  }

  List<Map<String, dynamic>> _normalizeTiers(List<dynamic> raw) {
    final out = raw.map(_normalizeTier).where((m) => m.isNotEmpty).toList();
    out.sort(
      (a, b) => (a['min_points'] as int).compareTo(b['min_points'] as int),
    );
    return out;
  }

  List<String> _parseBenefits(String text) =>
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, dynamic>? _currentTier(
    List<Map<String, dynamic>> tiers,
    int points,
  ) {
    for (final t in tiers) {
      final minPts = t['min_points'] as int;
      final maxPts = t['max_points'] as int;
      if (points >= minPts && points <= maxPts) return t;
    }
    return null; // no tier reached yet
  }

  double _progressToNext(
    int points,
    Map<String, dynamic> current,
    Map<String, dynamic>? next,
  ) {
    if (current.isEmpty || next == null) return 1.0;
    final minPts = current['min_points'] as int;
    final nextMin = next['min_points'] as int;
    if (nextMin <= minPts) return 1.0;
    final val = (points - minPts) / (nextMin - minPts);
    return val.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final rawTiers = (auth.rewardTiers ?? []) as List<dynamic>;
        final tiers = _normalizeTiers(rawTiers);
        final userPoints = (auth.userData?['points'] ?? 0) as int;

        if (tiers.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final current = _currentTier(tiers, userPoints);
        final idx = current != null ? tiers.indexOf(current) : -1;
        final next = idx >= 0 && idx + 1 < tiers.length
            ? tiers[idx + 1]
            : (current == null ? tiers.first : null);

        final progress = current != null
            ? _progressToNext(userPoints, current, next)
            : (next != null
                  ? (userPoints / (next['min_points'] as int)).clamp(0.0, 1.0)
                  : 0.0);

        final remainingToNext = next != null
            ? ((next['min_points'] as int) - userPoints).clamp(0, 1 << 30)
            : 0;

        final benefitsCurrent = current != null
            ? _parseBenefits(current['benefits_text'] as String)
            : const ['No benefits yet. Start earning points!'];

        final benefitLists = tiers
            .map((t) => _parseBenefits(t['benefits_text'] as String))
            .toList();
        final int maxBenefitsCount = benefitLists.fold<int>(
          0,
          (maxSoFar, list) => list.length > maxSoFar ? list.length : maxSoFar,
        );

        const double rowHeight = 28;
        const double basePadding = 170;
        final double carouselHeight =
            basePadding + (rowHeight * maxBenefitsCount);
        final (c1, c2) = current != null
            ? (current['color1'] as Color, current['color2'] as Color)
            : (tiers.first['color1'] as Color, tiers.first['color2'] as Color);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              "My Membership",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _CurrentTierHero(
                name: current != null ? current['name'] as String : 'General Member',
                price: current != null ? current['price_text'] as String : '',
                color1: c1,
                color2: c2,
                benefits: benefitsCurrent,
                progress: progress,
                nextTierName: next != null ? next['name'] as String : null,
                remainingPoints: next != null ? remainingToNext : null,
                userPoints: userPoints,
              ),
              const SizedBox(height: 16),
              Text(
                "Upgrade Your Plan",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: carouselHeight,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: tiers.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final t = tiers[i];
                    final isCurrent = current != null && identical(t, current);
                    final benefits = benefitLists[i];
                    final minPointsThis = (t['min_points'] as int? ?? 0);
                    final pointsNeeded = isCurrent
                        ? null
                        : (minPointsThis - userPoints).clamp(0, 1 << 30);

                    return AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      scale: i == _page ? 1.0 : 0.96,
                      child: _TierCardList(
                        name: t['name'] as String,
                        price: (t['price_text'] as String?) ?? '',
                        color1: t['color1'] as Color,
                        color2: t['color2'] as Color,
                        benefits: benefits,
                        isCurrent: isCurrent,
                        primaryActionLabel: isCurrent
                            ? "Current Plan"
                            : "$pointsNeeded Points Required",
                        primaryAction: null,
                        pointsNeeded: pointsNeeded,
                        maxBenefitsCount: maxBenefitsCount,
                        rowHeight: rowHeight,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  tiers.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _page == i ? 22 : 8,
                    decoration: BoxDecoration(
                      color: _page == i ? Colors.black87 : Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentTierHero extends StatelessWidget {
  final String name;
  final String price;
  final Color color1;
  final Color color2;
  final List<String> benefits;
  final double? progress;
  final String? nextTierName;
  final int? remainingPoints;
  final int userPoints;

  const _CurrentTierHero({
    Key? key,
    required this.name,
    required this.price,
    required this.color1,
    required this.color2,
    required this.benefits,
    this.progress,
    this.nextTierName,
    this.remainingPoints,
    required this.userPoints,
  }) : super(key: key);

  void _showBenefitsDialog(
    BuildContext context, {
    required List<String> benefits,
    required Color color1,
    required Color color2,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Text(
                'Membership Benefits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: benefits.length,
                  separatorBuilder: (_, __) => const Divider(height: 14),
                  itemBuilder: (context, i) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF22A45D),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            benefits[i],
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22A45D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1.withOpacity(0.95), color2.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TierHeader(name: name, price: price),
              ),
              const SizedBox(width: 8),
              if (userPoints > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "CURRENT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (nextTierName != null && remainingPoints != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                userPoints > 0
                    ? "Progress to $nextTierName"
                    : "Progress to first tier ($nextTierName)",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress?.clamp(0.0, 1.0) ?? 0.0,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.25),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${(progress! * 100).toStringAsFixed(0)}% — $remainingPoints pts to ${nextTierName}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBenefitsDialog(
                    context,
                    benefits: benefits.isEmpty
                        ? const ['No benefits available']
                        : benefits,
                    color1: color1,
                    color2: color2,
                  ),
                  icon: const Icon(Icons.card_membership, color: Colors.white),
                  label: const Text(
                    "Benefits",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierCardList extends StatelessWidget {
  final String name;
  final String price;
  final Color color1;
  final Color color2;
  final List<String> benefits;
  final bool isCurrent;
  final String primaryActionLabel;
  final VoidCallback? primaryAction;
  final int? pointsNeeded;

  // new:
  final int maxBenefitsCount;
  final double rowHeight;

  const _TierCardList({
    Key? key,
    required this.name,
    required this.price,
    required this.color1,
    required this.color2,
    required this.benefits,
    this.isCurrent = false,
    required this.primaryActionLabel,
    this.primaryAction,
    this.pointsNeeded,
    required this.maxBenefitsCount,
    required this.rowHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.2,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: primaryAction,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1.withOpacity(0.95), color2.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color2.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name.toUpperCase(), style: headStyle),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "CURRENT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (price.isNotEmpty)
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

              const SizedBox(height: 10),

              // Fixed-height benefits area so every card has same height
              SizedBox(
                height: rowHeight * maxBenefitsCount,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemExtent: rowHeight,
                  itemCount: benefits.length,
                  itemBuilder: (context, idx) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefits[idx],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: primaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.white24 : Colors.white,
                    foregroundColor: isCurrent ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: isCurrent ? 0 : 1,
                  ),
                  child: Text(
                    primaryActionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String name;
  final String price;
  final Color color1;
  final Color color2;
  final List<String> benefits;
  final bool isCurrent;
  final String primaryActionLabel;
  final VoidCallback? primaryAction;
  final int? pointsNeeded; // NEW

  const _TierCard({
    Key? key,
    required this.name,
    required this.price,
    required this.color1,
    required this.color2,
    required this.benefits,
    this.isCurrent = false,
    required this.primaryActionLabel,
    this.primaryAction,
    this.pointsNeeded,
  }) : super(key: key);

  List<Widget> _buildBenefitChips(List<String> all, {int maxVisible = 6}) {
    final visible = all.take(maxVisible).toList();
    final extra = all.length - visible.length;

    final chips = visible.map((b) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              b,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();

    if (extra > 0) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
          ),
          child: Text(
            "+$extra more",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final headStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.2,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: primaryAction,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1.withOpacity(0.95), color2.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color2.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name.toUpperCase(), style: headStyle),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "CURRENT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (price.isNotEmpty)
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

              const SizedBox(height: 10),

              // Benefits (capped to avoid overflow)
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: _buildBenefitChips(benefits, maxVisible: 6),
              // ),
              const SizedBox(height: 10),

              if (!isCurrent && pointsNeeded != null)
                Text(
                  "$pointsNeeded pts needed to unlock",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: primaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.white24 : Colors.white,
                    foregroundColor: isCurrent ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: isCurrent ? 0 : 1,
                  ),
                  child: Text(
                    primaryActionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  final String name;
  final String price;
  const _TierHeader({Key? key, required this.name, required this.price})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        if (price.isNotEmpty)
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }
}
