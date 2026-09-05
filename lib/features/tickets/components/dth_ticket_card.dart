import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/components/ticket_barcode.dart";
import "package:dth_v4/features/tickets/components/ticket_info_block.dart";
import "package:dth_v4/features/tickets/components/ticket_qr_with_outline.dart";
import "package:dth_v4/features/tickets/components/ticket_ref_label.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Digital event ticket card (white perforated background + optional advert band).
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

  PurchasedTicketItem? get _fallbackItem =>
      purchasedTicket.tickets.isNotEmpty ? purchasedTicket.tickets.first : null;

  PurchasedTicketItem? get _resolvedItem => ticketItem ?? _fallbackItem;

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

  String get _dateLabel {
    final raw = _field(ticketItem?.date, _fallbackItem?.date);
    return _formatTicketDate(raw);
  }

  /// Ticket card dates use dotted `dd.MM.yyyy` (e.g. `05.08.2026`).
  String _formatTicketDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == "—") return value;

    final match = RegExp(
      r"^(\d{1,2})[./\-](\d{1,2})[./\-](\d{4})$",
    ).firstMatch(value);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, "0");
      final month = match.group(2)!.padLeft(2, "0");
      final year = match.group(3)!;
      return "$day.$month.$year";
    }

    return value.replaceAll("/", ".").replaceAll("-", ".");
  }

  String get _timeLabel => _field(ticketItem?.time, _fallbackItem?.time);

  String get _location => _field(ticketItem?.location, _fallbackItem?.location);

  String get _ticketTypeLabel =>
      _field(ticketItem?.type, purchasedTicket.displayTitle);

  String get _reference => ticketItem?.ref.trim() ?? "";

  String get _qrData => ticketItem?.code.trim() ?? "";

  String get _advertImageUrl => _resolvedItem?.advertImageUrl.trim() ?? "";

  bool get _showAdvert => _resolvedItem?.hasAdvertImage ?? false;

  List<Widget> _buildBodyContent() {
    final reference = _reference;
    final valueMaxLines = forExport ? null : 3;
    final titleMaxLines = forExport ? null : 3;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: SvgPicture.asset(SvgAssets.dthText)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TicketBarcode(data: reference),
                Gap.h4,
                TicketRefLabel(
                  reference: reference.isNotEmpty ? reference : "—",
                ),
              ],
            ),
          ),
        ],
      ),
      Gap.h20,
      Center(child: TicketQrWithOutline(data: _qrData)),
      Gap.h(40),
      TicketInfoBlock(
        label: "EVENT",
        value: _eventTitle,
        maxLines: titleMaxLines,
      ),
      Gap.h16,
      Row(
        children: [
          Expanded(
            child: TicketInfoBlock(
              label: "DATE",
              value: _dateLabel,
              maxLines: valueMaxLines,
            ),
          ),
          Gap.w10,
          Expanded(
            child: TicketInfoBlock(
              label: "TIME",
              value: _timeLabel,
              maxLines: valueMaxLines,
            ),
          ),

          Expanded(
            child: TicketInfoBlock(
              label: "TYPE",
              value: _ticketTypeLabel,
              maxLines: valueMaxLines,
            ),
          ),
        ],
      ),
      Gap.h16,
      TicketInfoBlock(
        label: "LOCATION",
        value: _location,
        maxLines: valueMaxLines,
      ),
    ];
  }

  Widget? _buildAdvertBand() {
    if (!_showAdvert) return null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageAssets.ticketImageBg),
          fit: BoxFit.fill,
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: _advertImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(color: AppColors.greyTint25),
        errorWidget: (context, url, error) =>
            Container(color: AppColors.greyTint25),
      ),
    );
  }

  Widget _buildTicketBody() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageAssets.ticketBgNew),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: _buildBodyContent(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final advert = _buildAdvertBand();
    final ticket = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [_buildTicketBody(), if (advert != null) advert],
    );

    if (forExport) {
      return SizedBox(width: width, child: ticket);
    }

    final resolvedMaxHeight = _resolveMaxHeight(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: resolvedMaxHeight),
        child: ListView(
          shrinkWrap: true,
          primary: false,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [_buildTicketBody(), if (advert != null) advert],
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
