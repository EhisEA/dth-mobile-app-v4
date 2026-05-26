import "dart:async";
import "dart:io";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/services/app_audio_service.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/components/dth_ticket_card.dart";
import "package:dth_v4/features/tickets/models/your_tickets_args.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:gal/gal.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:screenshot/screenshot.dart";
import "package:share_plus/share_plus.dart";

class YourTicketsView extends StatefulWidget {
  const YourTicketsView({super.key, required this.purchasedTicket});

  YourTicketsView.fromArgs({super.key, required YourTicketsArgs args})
    : purchasedTicket = args.purchasedTicket;

  static const String path = NavigatorRoutes.yourTickets;

  final PurchasedTicket purchasedTicket;

  @override
  State<YourTicketsView> createState() => _YourTicketsViewState();
}

class _YourTicketsViewState extends State<YourTicketsView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late final PageController _pageController;

  int _activeIndex = 0;
  bool _isExporting = false;

  PurchasedTicket get _purchased => widget.purchasedTicket;

  int get _ticketCount => _purchased.count;

  PurchasedTicketItem? _ticketItemAt(int index) {
    final tickets = _purchased.tickets;
    if (index < tickets.length) return tickets[index];
    return null;
  }

  String _exportFileName(int index) {
    final ref = _ticketItemAt(index)?.ref.trim();
    if (ref != null && ref.isNotEmpty) return "dth_ticket_$ref";
    return "dth_ticket_${index + 1}";
  }

  String _shareTextFor(int index) {
    final item = _ticketItemAt(index);
    final eventName = item?.eventName.trim();
    if (eventName != null && eventName.isNotEmpty) {
      return "My ticket for $eventName";
    }
    return "My DTH event ticket";
  }

  Widget _ticketForCapture(int index) {
    final width = MediaQuery.sizeOf(context).width * 0.88;
    return DthTicketCard(
      purchasedTicket: _purchased,
      ticketItem: _ticketItemAt(index),
      forExport: true,
      width: width,
    );
  }

  Future<Uint8List?> _captureTicket(int index) async {
    final captureContext = context;
    final mediaQuery = MediaQuery.of(captureContext);
    final width = mediaQuery.size.width * 0.88;

    // Theme/MediaQuery are applied via [context] inside the screenshot package.
    return _screenshotController.captureFromLongWidget(
      Material(color: Colors.transparent, child: _ticketForCapture(index)),
      delay: const Duration(milliseconds: 100),
      pixelRatio: mediaQuery.devicePixelRatio,
      context: captureContext,
      constraints: BoxConstraints(maxWidth: width),
    );
  }

  Future<File> _writeTicketImage(Uint8List image, int index) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      path.join(directory.path, "${_exportFileName(index)}.png"),
    );
    await file.writeAsBytes(image, flush: true);
    return file;
  }

  void _showMessage({
    required bool isError,
    required String title,
    required String message,
  }) {
    if (!mounted) return;

    if (isError) {
      DthFlushBar.instance.showError(title: title, message: message);
    } else {
      DthFlushBar.instance.showSuccess(title: title, message: message);
    }
  }

  Future<void> _runExport(Future<void> Function(Uint8List image) action) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    unawaited(AppAudioService.instance.playScreenshotSound());

    try {
      // After navigation/resume the first frame can report loose constraints;
      // wait for layout before capture so the on-screen card does not overflow.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final image = await _captureTicket(_activeIndex);
      if (image == null || image.isEmpty) {
        throw Exception("Screenshot capture failed.");
      }
      await action(image);
    } catch (e) {
      _showMessage(
        isError: true,
        title: "Could not export ticket",
        message: "Please try again.",
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> downloadActiveTicket() async {
    await _runExport((image) async {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw Exception("Photo library access denied.");
        }
      }

      await Gal.putImageBytes(image, name: _exportFileName(_activeIndex));

      _showMessage(
        isError: false,
        title: "Ticket saved",
        message: "The ticket has been saved to your photo library.",
      );
    });
  }

  Future<void> shareActiveTicket() async {
    await _runExport((image) async {
      final imageFile = await _writeTicketImage(image, _activeIndex);
      final params = ShareParams(
        files: [XFile(imageFile.path)],
        text: _shareTextFor(_activeIndex),
      );
      await SharePlus.instance.share(params);
    });
  }

  Future<void> _onDownloadTap() async {
    if (_isExporting) return;
    HapticFeedback.lightImpact();
    await downloadActiveTicket();
  }

  Future<void> _onShareTap() async {
    if (_isExporting) return;
    HapticFeedback.lightImpact();
    await shareActiveTicket();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchased = _purchased;
    final issuedTickets = purchased.tickets;
    final count = _ticketCount;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: DthAppBar(
        title: "Your Tickets",
        actions: [
          // IconButton(
          //   onPressed: _isExporting ? null : _onShareTap,
          //   icon: SvgPicture.asset(
          //     SvgAssets.share,
          //     width: 20,
          //     height: 20,
          //     colorFilter: ColorFilter.mode(AppColors.black, BlendMode.srcIn),
          //   ),
          // ),
          IconButton(
            onPressed: _isExporting ? null : _onDownloadTap,
            icon: SvgPicture.asset(
              SvgAssets.download,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(AppColors.black, BlendMode.srcIn),
            ),
          ),
          Gap.w4,
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              padEnds: true,
              itemCount: count,
              onPageChanged: (index) => setState(() => _activeIndex = index),
              itemBuilder: (context, index) {
                final ticketItem = index < issuedTickets.length
                    ? issuedTickets[index]
                    : null;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DthTicketCard(
                        purchasedTicket: purchased,
                        ticketItem: ticketItem,
                        maxHeight: constraints.maxHeight,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Gap.h24,
        ],
      ),
    );
  }
}
