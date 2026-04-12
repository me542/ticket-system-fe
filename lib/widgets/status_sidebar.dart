import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/services/api_attachment.dart';
import '../core/services/api_file.dart';
import '../core/services/api_login.dart';
import '../core/services/api_user_data.dart';
import '../data/app_theme.dart';
import '../models/ticket.dart';
import 'package:ticket_system/core/services/api_update_ticket.dart';

class TicketSidebar extends StatefulWidget {
  final Ticket? ticket;
  final VoidCallback onClose;

  const TicketSidebar({
    super.key,
    required this.ticket,
    required this.onClose,
  });

  @override
  State<TicketSidebar> createState() => _TicketSidebarState();
}

class _TicketSidebarState extends State<TicketSidebar> {
  Map<String, dynamic>? _detail;
  bool _isLoading = false;
  String? _error;

  String _currentUserRole     = '';
  String _currentUsername     = '';
  bool   _actionLoading       = false;

  // ─── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchBySR(widget.ticket?.id);
    _loadCurrentUser();
  }

  @override
  void didUpdateWidget(covariant TicketSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ticket?.id != oldWidget.ticket?.id) {
      _fetchBySR(widget.ticket?.id);
    }
  }

  // ─── load current user ─────────────────────────────────────────────────────

  Future<void> _loadCurrentUser() async {
    try {
      final savedUsername = await ApiLogin.getUsername();
      final users         = await ApiGetUser.fetchUsers();

      String role = '';
      String username = savedUsername ?? '';

      if (savedUsername != null && savedUsername.isNotEmpty) {
        final match = users.firstWhere(
              (u) => (u['username'] ?? '').toLowerCase() == savedUsername.toLowerCase(),
          orElse: () => {},
        );
        role = match['role'] ?? '';
      }

      if (role.isEmpty && users.isNotEmpty) {
        role = users.first['role'] ?? '';
      }

      debugPrint('👤 user: "$username"  role: "$role"');

      if (mounted) {
        setState(() {
          _currentUserRole = role.toLowerCase().trim();
          _currentUsername = username.toLowerCase().trim();
        });
      }
    } catch (e) {
      debugPrint('Could not load current user: $e');
    }
  }

  // ─── fetch ticket ──────────────────────────────────────────────────────────

  Future<void> _fetchBySR(String? srNumber) async {
    if (srNumber == null || srNumber.trim().isEmpty) return;
    setState(() { _isLoading = true; _error = null; _detail = null; });
    try {
      final data = await ApiTicket.getTicketByID(srNumber.trim());
      setState(() { _detail = data; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error     = 'Could not load ticket details. Please try again.';
        _isLoading = false;
      });
    }
  }

  // ─── field helpers ─────────────────────────────────────────────────────────

  dynamic _pick(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  String _field(List<String> keys, {String fallback = '—'}) {
    if (_detail == null) return fallback;
    final v = _pick(_detail!, keys);
    return v?.toString() ?? fallback;
  }

  // ─── status helpers ────────────────────────────────────────────────────────

  String get _rawStatus =>
      _field(['status'], fallback: widget.ticket?.status.name ?? '')
          .toLowerCase()
          .trim();

  String get _normalizedStatus {
    switch (_rawStatus.replaceAll(' ', '').replaceAll('_', '')) {
      case 'forendorsement':
      case 'pendingendorsement':
      case 'submitted':
      case 'new':
        return 'submitted';
      case 'endorsed':
      case 'forapproval':
      case 'pendingapproval':
      case 'forassessment':
      case 'assessment':
        return 'endorsed';
      case 'approved':
      case 'forassignment':
      case 'pendingassignment':
        return 'approved';
      case 'assigned':
      case 'inprogress':
        return 'assigned';
      case 'resolved':
        return 'resolved';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        debugPrint('⚠️  Unknown ticket status: "$_rawStatus"');
        return _rawStatus.replaceAll(' ', '');
    }
  }

  bool get _isSubmitted => _normalizedStatus == 'submitted';
  bool get _isEndorsed  => _normalizedStatus == 'endorsed';
  bool get _isApproved  => _normalizedStatus == 'approved';
  bool get _isAssigned  => _normalizedStatus == 'assigned';
  bool get _isResolved  => _normalizedStatus == 'resolved';
  bool get _isCancelled => _normalizedStatus == 'cancelled';

  // ─── who created this ticket ───────────────────────────────────────────────

  /// Returns true if the logged-in user is the one who submitted this ticket.
  bool get _isCreator {
    final submitter = _field(
      ['username', 'submitter', 'created_by'],
      fallback: widget.ticket?.submitter ?? '',
    ).toLowerCase().trim();
    return _currentUsername.isNotEmpty && _currentUsername == submitter;
  }

  // ─── color helpers ─────────────────────────────────────────────────────────

  Color get _statusColor {
    switch (widget.ticket?.status) {
      case TicketStatus.forAssessment: return AppTheme.statusAssessment;
      case TicketStatus.inProgress:    return AppTheme.statusProgress;
      case TicketStatus.resolved:      return AppTheme.statusResolved;
      case TicketStatus.cancelled:     return AppTheme.statusCancelled;
      default:                         return AppTheme.statusAssessment;
    }
  }

  Color get _priorityColor {
    switch (widget.ticket?.priority) {
      case TicketPriority.priority1: return AppTheme.priority1;
      case TicketPriority.priority2: return AppTheme.priority2;
      case TicketPriority.priority3: return AppTheme.priority3;
      default:                       return AppTheme.priority3;
    }
  }

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    if (ticket == null) return const SizedBox();

    return Material(
      elevation: 20,
      child: Container(
        width: 940,
        color: AppTheme.sidebarBg,
        child: Column(
          children: [
            _buildHeader(ticket),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                  ? _buildError()
                  : _buildContent(ticket),
            ),
          ],
        ),
      ),
    );
  }

  // ─── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(Ticket ticket) {
    // Cancel is only shown to the ticket creator while still active
    final canCancel = _isCreator && !_isResolved && !_isCancelled;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: const Text(
              'Ticket Detail',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ── Cancel button (creator only) ────────────────────────────────
          if (canCancel)
            Tooltip(
              message: 'Cancel Ticket',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _actionLoading ? null : () => _confirmAndCancel(ticket.id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.block_outlined, size: 14, color: Colors.orange),
                        SizedBox(width: 5),
                        Text('Cancel',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          IconButton(
            onPressed: () => _fetchBySR(ticket.id),
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── confirm cancel dialog ─────────────────────────────────────────────────

  Future<void> _confirmAndCancel(String ticketId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancel Ticket',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to cancel this ticket? This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _handleAction('cancel', ticketId);
  }

  // ─── loading / error ───────────────────────────────────────────────────────

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading ticket details…',
            style: TextStyle(color: AppTheme.textSecondary)),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _fetchBySR(widget.ticket?.id),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  // ─── main content ──────────────────────────────────────────────────────────

  Widget _buildContent(Ticket ticket) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT COLUMN ──────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _chip(ticket.statusLabel, _statusColor),
                    const SizedBox(width: 8),
                    _chip(ticket.priorityLabel, _priorityColor),
                  ]),
                  const SizedBox(height: 16),
                  _buildSubjectCard(ticket),
                  const SizedBox(height: 12),
                  _buildDetailsCard(ticket),
                  const SizedBox(height: 12),
                  _buildDescriptionCard(),
                  const SizedBox(height: 12),
                  _buildAttachmentsCard(),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // ── RIGHT COLUMN ─────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressStepper(ticket),
                  const SizedBox(height: 16),
                  _buildApprovalChain(),
                  const SizedBox(height: 12),
                  _buildActionButtons(ticket),
                  const SizedBox(height: 16),
                  _buildReplySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── subject card ──────────────────────────────────────────────────────────

  Widget _buildSubjectCard(Ticket ticket) {
    final subject = _field(['subject', 'title'], fallback: ticket.title);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.confirmation_number, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Text('SR #${ticket.id}',
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(subject,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── details card ──────────────────────────────────────────────────────────

  Widget _buildDetailsCard(Ticket ticket) {
    final category    = _field(['category'], fallback: ticket.categoryLabel);
    final submitter   = _field(['username', 'submitter', 'created_by'], fallback: ticket.submitter);
    final institution = _field(['institution', 'organization', 'company']);
    final ticketType  = _field(['tickettype', 'ticket_type', 'type']);
    final createdRaw  = _field(['CreatedAt', 'created_at', 'createdAt', 'date_created']);
    final createdAt   = _parseDate(createdRaw) ?? ticket.createdAt;
    final createdStr  =
        '${createdAt.year}-${_p(createdAt.month)}-${_p(createdAt.day)}'
        '  ${_p(createdAt.hour)}:${_p(createdAt.minute)}:${_p(createdAt.second)}';

    return _card(
      child: Column(
        children: [
          _detailRow(Icons.category_outlined, 'Category',     category),
          _detailRow(Icons.person_outline,    'Submitter',    submitter),
          if (institution != '—')
            _detailRow(Icons.business_outlined, 'Organization', institution),
          if (ticketType != '—')
            _detailRow(Icons.label_outline,   'Type',         ticketType),
          _detailRow(Icons.access_time,       'Created',      createdStr),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ─── description ───────────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
    final desc = _field(['description', 'details', 'body'],
        fallback: widget.ticket?.description ?? '');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Description'),
          const SizedBox(height: 8),
          Text(
            desc.isEmpty ? 'No description provided.' : desc,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.55),
          ),
        ],
      ),
    );
  }

  // ─── attachments ───────────────────────────────────────────────────────────

  Widget _buildAttachmentsCard() {
    final raw = _detail?['attachments'];
    final List<dynamic> attachments = (raw is List) ? raw : [];
    if (attachments.isEmpty) return const SizedBox();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Attachments'),
          const SizedBox(height: 10),
          ...attachments.map((att) {
            final filePath = (att['file_path'] ?? '').toString();
            final fileName =
            (att['file_name'] ?? filePath.split('/').last).toString();
            final url     = filePath;
            final isImage = RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$',
                caseSensitive: false)
                .hasMatch(fileName);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.sidebarBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImage && url.isNotEmpty)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _fetchAndOpen(url, fileName),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          child: _AuthImage(url: url, height: 160),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isImage
                              ? Icons.image_outlined
                              : Icons.insert_drive_file_outlined,
                          color: isImage ? Colors.blue : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(fileName,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        if (url.isNotEmpty)
                          _attachmentButton(
                            icon: Icons.open_in_new,
                            label: 'View',
                            color: Colors.blue,
                            onTap: () => _fetchAndOpen(url, fileName),
                          ),
                        const SizedBox(width: 6),
                        if (url.isNotEmpty)
                          _attachmentButton(
                            icon: Icons.download_outlined,
                            label: 'Save',
                            color: Colors.green,
                            onTap: () =>
                                _fetchAndOpen(url, fileName, download: true),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _attachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndOpen(String url, String fileName,
      {bool download = false}) async {
    try {
      if (download) {
        await ApiAttachment.downloadFile(url, fileName);
      } else {
        await ApiAttachment.viewFile(url, fileName);
      }
    } catch (e) {
      _showSnackbar('Failed: $e', color: Colors.redAccent);
    }
  }

  void _showSnackbar(String msg, {Color color = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── progress stepper ──────────────────────────────────────────────────────

  Widget _buildProgressStepper(Ticket ticket) {
    const steps = [
      'Submitted', 'Endorsed', 'Approved',
      'Assigned', 'In Progress', 'Resolved'
    ];

    int active = 0;
    if (_isEndorsed) active = 1;
    if (_isApproved) active = 2;
    if (_isAssigned) active = 3;
    if (_isAssigned &&
        _rawStatus.replaceAll(' ', '') == 'inprogress') active = 4;
    if (_isResolved)  active = 5;
    if (_isCancelled) active = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Ticket Progress'),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (i) {
            final done    = i <= active;
            final current = i == active;
            return Expanded(
              child: Column(
                children: [
                  Row(children: [
                    if (i != 0)
                      Expanded(
                          child: Container(
                              height: 2,
                              color: i <= active
                                  ? Colors.green
                                  : Colors.grey.shade800)),
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: done
                          ? (current
                          ? Colors.green.shade600
                          : Colors.green)
                          : Colors.grey.shade800,
                      child: done
                          ? const Icon(Icons.check,
                          color: Colors.white, size: 13)
                          : Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                    if (i != steps.length - 1)
                      Expanded(
                          child: Container(
                              height: 2,
                              color: i < active
                                  ? Colors.green
                                  : Colors.grey.shade800)),
                  ]),
                  const SizedBox(height: 5),
                  Text(
                    steps[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: done ? Colors.white : Colors.grey,
                      fontWeight:
                      current ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── approval chain ────────────────────────────────────────────────────────
  //
  // Shows the actual name of whoever endorsed / approved / assigned / resolved.
  // Falls back to "No X assigned" if the field is empty.

  Widget _buildApprovalChain() {
    // ── Pull names from API response ────────────────────────────────────────
    // Adjust these key lists to match whatever your backend returns.
    final endorserName = _field(['endorser', 'endorser_name', 'endorsed_by']);
    final approverName = _field(['approver', 'approver_name', 'approved_by']);
    final assigneeName = _field(['assigned_to', 'assignee', 'resolver_name', 'resolver']);
    final resolverName = assigneeName; // same person resolves after grab

    final endorseDone = _isEndorsed || _isApproved || _isAssigned || _isResolved || _isCancelled;
    final approveDone = _isApproved || _isAssigned || _isResolved || _isCancelled;
    final assignDone  = _isAssigned || _isResolved || _isCancelled;
    final resolveDone = _isResolved || _isCancelled;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Approval Chain'),
          const SizedBox(height: 14),

          // ── Step 1: Endorser ────────────────────────────────────────────
          _chainRow(
            name:        endorserName != '—' ? endorserName : 'No endorser assigned',
            role:        'Endorser',
            isDone:      endorseDone,
            isActive:    !endorseDone,
            isLocked:    false,
            statusText:  endorseDone ? 'Endorsed ✓' : 'Awaiting',
            statusColor: endorseDone ? Colors.green : Colors.orange,
          ),

          Divider(color: Colors.grey.shade800),

          // ── Step 2: Approver ────────────────────────────────────────────
          _chainRow(
            name:        approverName != '—' ? approverName : 'No approver assigned',
            role:        'Approver',
            isDone:      approveDone,
            isActive:    endorseDone && !approveDone,
            isLocked:    !endorseDone,
            statusText:  approveDone
                ? 'Approved ✓'
                : (endorseDone ? 'Awaiting' : 'Locked'),
            statusColor: approveDone
                ? Colors.green
                : (endorseDone ? Colors.orange : Colors.grey.shade600),
          ),

          Divider(color: Colors.grey.shade800),

          // ── Step 3: Assignee ────────────────────────────────────────────
          _chainRow(
            name:        assigneeName != '—' ? assigneeName : 'No assignee yet',
            role:        'Assigned To',
            isDone:      assignDone,
            isActive:    approveDone && !assignDone,
            isLocked:    !approveDone,
            statusText:  assignDone
                ? 'Assigned ✓'
                : (approveDone ? 'Awaiting' : 'Locked'),
            statusColor: assignDone
                ? Colors.green
                : (approveDone ? Colors.purple : Colors.grey.shade600),
          ),

          Divider(color: Colors.grey.shade800),

          // ── Step 4: Resolver ────────────────────────────────────────────
          _chainRow(
            name:        resolverName != '—' ? resolverName : 'Awaiting assignee',
            role:        'Resolver',
            isDone:      resolveDone,
            isActive:    assignDone && !resolveDone,
            isLocked:    !assignDone,
            statusText:  _isCancelled
                ? 'Cancelled'
                : (resolveDone
                ? 'Resolved ✓'
                : (assignDone ? 'In Progress' : 'Locked')),
            statusColor: _isCancelled
                ? Colors.redAccent
                : (resolveDone
                ? Colors.teal
                : (assignDone ? Colors.blue : Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _chainRow({
    required String name,
    required String role,
    required bool   isDone,
    required bool   isActive,
    required bool   isLocked,
    required String statusText,
    required Color  statusColor,
  }) {
    // Derive initials from the actual name
    final initials = _initialsFrom(name);

    final Color avatarColor = isDone
        ? Colors.green.shade700
        : isActive
        ? Colors.orange.shade700
        : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor,
            child: isLocked
                ? const Icon(Icons.lock_outline, color: Colors.white54, size: 16)
                : isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isLocked ? AppTheme.textMuted : AppTheme.textPrimary,
                    fontSize: 13,
                    fontStyle: isLocked ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                Text(role,
                    style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Returns up to 2 initials from a name string.
  String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'[\s._]+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ─── action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(Ticket ticket) {
    final role = _currentUserRole.toLowerCase().trim();

    if (role.isEmpty) {
      return _actionCard(children: const [
        SizedBox(height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ]);
    }

    final endorseDone = _isEndorsed || _isApproved || _isAssigned || _isResolved || _isCancelled;
    final approveDone = _isApproved || _isAssigned || _isResolved || _isCancelled;
    final assignDone  = _isAssigned || _isResolved || _isCancelled;
    final resolveDone = _isResolved || _isCancelled;

    final isEndorser = role == 'endorser' || role.startsWith('endorser');
    final isApprover = role == 'approver' || role.startsWith('approver');
    final isResolver = role == 'resolver' || role.startsWith('resolver') || role.contains('resolv');

    // ── Cancelled ────────────────────────────────────────────────────────────
    if (_isCancelled) {
      return _actionCard(children: [
        const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        const Text('This ticket has been cancelled.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ]);
    }

    // ── ENDORSER ─────────────────────────────────────────────────────────────
    if (isEndorser) {
      if (!endorseDone) {
        return _actionCard(
          debugLabel: 'endorser · $_normalizedStatus',
          children: [
            _actionBtn(
              label: 'Endorse',
              icon: Icons.thumb_up_alt_outlined,
              color: Colors.green,
              onTap: () => _handleAction('endorse', ticket.id),
            ),
            const SizedBox(width: 12),
            _actionBtn(
              label: 'Reject',
              icon: Icons.thumb_down_alt_outlined,
              color: Colors.redAccent,
              onTap: () => _handleAction('reject', ticket.id),
            ),
          ],
        );
      }
      return _actionCard(children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
        const SizedBox(width: 8),
        const Text('Ticket has been endorsed.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ]);
    }

    // ── APPROVER ─────────────────────────────────────────────────────────────
    if (isApprover) {
      if (!endorseDone) {
        return _actionCard(children: [
          const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          const Text('Waiting for endorsement first.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ]);
      }
      if (!approveDone) {
        return _actionCard(
          debugLabel: 'approver · $_normalizedStatus',
          children: [
            _actionBtn(
              label: 'Approve',
              icon: Icons.verified_outlined,
              color: Colors.blue,
              onTap: () => _handleAction('approve', ticket.id),
            ),
            const SizedBox(width: 12),
            _actionBtn(
              label: 'Reject',
              icon: Icons.cancel_outlined,
              color: Colors.redAccent,
              onTap: () => _handleAction('reject', ticket.id),
            ),
          ],
        );
      }
      return _actionCard(children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
        const SizedBox(width: 8),
        const Text('Ticket has been approved.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ]);
    }

    // ── RESOLVER ─────────────────────────────────────────────────────────────
    if (isResolver) {
      if (!approveDone) {
        return _actionCard(children: [
          const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          const Text('Waiting for approval first.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ]);
      }
      if (!assignDone) {
        return _actionCard(
          debugLabel: 'resolver · $_normalizedStatus',
          children: [
            _actionBtn(
              label: 'Grab Ticket',
              icon: Icons.handshake_outlined,
              color: Colors.purple,
              onTap: () => _handleAction('grab', ticket.id),
            ),
            const SizedBox(width: 12),
            _actionBtn(
              label: 'Reject',
              icon: Icons.cancel_outlined,
              color: Colors.redAccent,
              onTap: () => _handleAction('reject', ticket.id),
            ),
          ],
        );
      }
      if (!resolveDone) {
        return _actionCard(
          debugLabel: 'resolver (assigned) · $_normalizedStatus',
          children: [
            _actionBtn(
              label: 'Resolve',
              icon: Icons.task_alt_outlined,
              color: Colors.teal,
              onTap: () => _handleAction('resolve', ticket.id),
            ),
          ],
        );
      }
      return _actionCard(children: [
        const Icon(Icons.check_circle, color: Colors.teal, size: 18),
        const SizedBox(width: 8),
        const Text('Ticket has been resolved.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ]);
    }

    // ── Fallback ──────────────────────────────────────────────────────────────
    return _actionCard(
      debugLabel: 'role: "$role" · status: "$_normalizedStatus"',
      children: const [
        Text('No actions available for your role at this stage.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _actionCard({required List<Widget> children, String? debugLabel}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Actions'),
          if (debugLabel != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4)),
              child: Text(debugLabel,
                  style:
                  const TextStyle(color: Colors.grey, fontSize: 9)),
            ),
          ],
          const SizedBox(height: 10),
          if (_actionLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else
            Row(children: children),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _actionLoading ? null : onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.55)),
          ),
          child: Row(
            mainAxisSize:
            fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
    return fullWidth ? Expanded(child: btn) : btn;
  }

  // ─── handle action ─────────────────────────────────────────────────────────

  Future<void> _handleAction(String action, String ticketId) async {
    setState(() => _actionLoading = true);
    try {
      final token = await ApiLogin.getToken();
      if (token == null || token.isEmpty) {
        _showSnackbar('Not authenticated. Please log in again.',
            color: Colors.redAccent);
        return;
      }

      Map<String, dynamic> result;
      switch (action) {
        case 'endorse':
          result = await ApiUpdateTicket.endorseTicket(token, ticketId);
          _showSnackbar(result['message'] ?? 'Ticket endorsed ✓',
              color: Colors.green);
          break;
        case 'approve':
          result = await ApiUpdateTicket.approveTicket(token, ticketId);
          _showSnackbar(result['message'] ?? 'Ticket approved ✓',
              color: Colors.blue);
          break;
        case 'grab':
          result = await ApiUpdateTicket.assignTicket(token, ticketId);
          _showSnackbar(result['message'] ?? 'Ticket assigned to you ✓',
              color: Colors.purple);
          break;
        case 'reject':
          result = await ApiUpdateTicket.rejectTicket(token, ticketId);
          _showSnackbar(result['message'] ?? 'Ticket rejected',
              color: Colors.redAccent);
          break;
        case 'resolve':
          result = await ApiUpdateTicket.resolveTicket(token, ticketId);
          _showSnackbar(result['message'] ?? 'Ticket resolved ✓',
              color: Colors.teal);
          break;
        case 'cancel':
          result = await ApiUpdateTicket.cancelTicket(token, ticketId);
          _showSnackbar(result['message'] ?? 'Ticket cancelled',
              color: Colors.orange);
          break;
        default:
          _showSnackbar('Unknown action: $action', color: Colors.orange);
          return;
      }

      await _fetchBySR(ticketId);
    } catch (e) {
      _showSnackbar('Action failed: $e', color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // ─── reply section ─────────────────────────────────────────────────────────

  Widget _buildReplySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Reply'),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            hintText: 'Write a reply…',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Post Reply'),
          ),
        ),
      ],
    );
  }

  // ─── shared widgets ────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    ),
  );

  String _p(int n) => n.toString().padLeft(2, '0');

  DateTime? _parseDate(String raw) {
    if (raw == '—' || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

// ─── Auth-aware image widget ───────────────────────────────────────────────────

class _AuthImage extends StatefulWidget {
  final String url;
  final double height;
  const _AuthImage({required this.url, this.height = 160});

  @override
  State<_AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<_AuthImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiAttachment.fetchBytes(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
              height: widget.height,
              color: AppTheme.surface,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snap.data == null) {
          return Container(
              height: widget.height,
              color: AppTheme.surface,
              child: const Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.grey, size: 32)));
        }
        return Image.memory(snap.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: widget.height);
      },
    );
  }
}