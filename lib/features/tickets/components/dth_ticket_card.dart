import "package:barcode/barcode.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:qr_flutter/qr_flutter.dart";

/// Digital event ticket card (background, title art, QR frame assets).
class DthTicketCard extends StatelessWidget {
  const DthTicketCard({
    super.key,
    required this.purchasedTicket,
    this.ticketItem,
    this.forExport = false,
    this.width,
    this.maxHeight,
  });

  final PurchasedTicket purchasedTicket;
  final PurchasedTicketItem? ticketItem;

  /// When true, lays out all content in a fixed-height [Column] for image export.
  /// When false, height follows content up to [maxHeight], then scrolls.
  final bool forExport;
  final double? width;

  /// Max height for on-screen layout (from the [PageView] slot). Avoids relying on
  /// [LayoutBuilder] constraints during the first frame after navigation/resume.
  final double? maxHeight;

  static const Color _labelColor = Color(0xFFD0C2FF);
  static const Color _valueColor = Color(0xFFFCFCFC);

  PurchasedTicketItem? get _fallbackItem =>
      purchasedTicket.tickets.isNotEmpty ? purchasedTicket.tickets.first : null;

  String _field(String? primary, String? fallback) {
    final value = primary?.trim();
    if (value != null && value.isNotEmpty) return value;
    final alt = fallback?.trim();
    if (alt != null && alt.isNotEmpty) return alt;
    return "—";
  }

  String get _eventTitle => _field(
    ticketItem?.eventName,
    _fallbackItem?.eventName.isNotEmpty == true
        ? _fallbackItem!.eventName
        : purchasedTicket.displayTitle,
  );

  String get _dateLabel => _field(ticketItem?.date, _fallbackItem?.date);

  String get _timeLabel => _field(ticketItem?.time, _fallbackItem?.time);

  String get _location => _field(ticketItem?.location, _fallbackItem?.location);

  String get _ticketTypeLabel =>
      _field(ticketItem?.type, purchasedTicket.displayTitle);

  String get _reference => ticketItem?.ref.trim() ?? "";

  String get _qrData => ticketItem?.code.trim() ?? "";

  List<Widget> _buildContent() {
    final reference = _reference;
    final valueMaxLines = forExport ? null : 3;
    final titleMaxLines = forExport ? null : 3;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(SvgAssets.dthText, fit: BoxFit.contain),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TicketBarcode(data: reference),
              Gap.h4,
              AppText.regular(
                "REF: ${reference.isNotEmpty ? reference : "—"}",
                fontSize: 9,
                color: _valueColor.withValues(alpha: 0.85),
                letterSpacing: -0.2,
              ),
            ],
          ),
        ],
      ),
      Gap.h10,
      Image.asset(ImageAssets.ticketTitle),
      Gap.h32,
      AppText.bold(
        _eventTitle,
        fontSize: 20,
        color: _valueColor,
        letterSpacing: -0.3,
        maxLines: titleMaxLines,
        multiText: true,
        height: 1.3,
      ),
      Gap.h32,
      Row(children: [_QrWithOutline(data: _qrData)]),
      Gap.h12,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _InfoBlock(
              label: "DATE",
              value: _dateLabel,
              maxLines: valueMaxLines,
            ),
          ),
          Gap.w16,
          Expanded(
            child: _InfoBlock(
              label: "TIME",
              value: _timeLabel,
              maxLines: valueMaxLines,
            ),
          ),
        ],
      ),
      Gap.h12,
      _InfoBlock(label: "LOCATION", value: _location, maxLines: valueMaxLines),
      Gap.h12,
      _InfoBlock(
        label: "TYPE",
        value: _ticketTypeLabel,
        maxLines: valueMaxLines,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      image: const DecorationImage(
        image: AssetImage(ImageAssets.ticketBg),
        fit: BoxFit.cover,
      ),
    );

    final content = _buildContent();

    if (forExport) {
      return Container(
        width: width,
        padding: const EdgeInsets.all(32),
        clipBehavior: Clip.antiAlias,
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: content,
        ),
      );
    }

    final resolvedMaxHeight = _resolveMaxHeight(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: resolvedMaxHeight),
        child: DecoratedBox(
          decoration: decoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.hardEdge,
            child: ListView(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.all(32),
              physics: const BouncingScrollPhysics(),
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  double _resolveMaxHeight(BuildContext context) {
    final explicit = maxHeight;
    if (explicit != null && explicit.isFinite && explicit > 0) {
      return explicit;
    }

    final mediaQuery = MediaQuery.sizeOf(context);
    return mediaQuery.height * 0.72;
  }
}

class _QrWithOutline extends StatelessWidget {
  const _QrWithOutline({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            ImageAssets.ticketQrCodeOutline,
            width: 172,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 8,
              left: 4,
              right: 4,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QrImageView(
                data: data.isNotEmpty ? data : "dth-ticket",
                size: 152,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.maxLines = 3,
  });

  final String label;
  final String value;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.cascadiaMonoBold(
          label,
          fontSize: 8,
          color: DthTicketCard._labelColor,
          letterSpacing: 1.8,
        ),
        Gap.h4,
        AppText.semiBold(
          value,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: DthTicketCard._valueColor,
          letterSpacing: -0.2,
          maxLines: maxLines,
          multiText: true,
          height: 1.25,
        ),
      ],
    );
  }
}

class _TicketBarcode extends StatelessWidget {
  const _TicketBarcode({required this.data});

  final String data;

  static final Barcode _barcode = Barcode.code128();

  @override
  Widget build(BuildContext context) {
    final value = data.trim().isNotEmpty ? data.trim() : "0";

    try {
      final svg = _barcode.toSvg(
        value,
        width: 75,
        height: 14,
        drawText: false,
        color: 0xFFFFFF,
      );
      return SizedBox(
        width: 75,
        height: 14,
        child: SvgPicture.string(svg, fit: BoxFit.fill),
      );
    } catch (_) {
      return const SizedBox(width: 72, height: 28);
    }
  }
}
