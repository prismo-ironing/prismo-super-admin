import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/support_ticket.dart';
import '../services/support_ticket_service.dart';

class SupportTicketsManagementScreen extends StatefulWidget {
  const SupportTicketsManagementScreen({super.key});

  @override
  State<SupportTicketsManagementScreen> createState() => _SupportTicketsManagementScreenState();
}

class _SupportTicketsManagementScreenState extends State<SupportTicketsManagementScreen> {
  TicketsResponse? _ticketsResponse;
  TicketStatistics? _statistics;
  bool _isLoading = true;
  bool _isLoadingStatistics = true;
  String? _error;
  
  // Filters
  String? _selectedStatus;
  String? _selectedPriority;
  String? _searchOrderId;
  String? _searchCustomerId;
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _customerIdController = TextEditingController();
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  
  // Selected ticket for detail view
  SupportTicket? _selectedTicket;
  bool _showDetailPanel = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadStatistics();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tickets = await SupportTicketService.getAllTickets(
        status: _selectedStatus,
        priority: _selectedPriority,
        orderId: _searchOrderId?.isEmpty ?? true ? null : _searchOrderId,
        customerId: _searchCustomerId?.isEmpty ?? true ? null : _searchCustomerId,
        page: _currentPage,
        size: _pageSize,
      );

      setState(() {
        _ticketsResponse = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStatistics = true;
    });

    try {
      final stats = await SupportTicketService.getTicketStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStatistics = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoadingStatistics = false;
      });
    }
  }

  Future<void> _updateTicketStatus(String ticketId, String newStatus) async {
    try {
      final result = await SupportTicketService.updateTicketStatus(
        ticketId,
        newStatus,
        'super-admin',
      );

      if (result['success'] == true) {
        final ticket = result['ticket'] as SupportTicket;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket status updated to ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadData();
        _loadStatistics();
        if (_selectedTicket?.id == ticketId) {
          setState(() {
            _selectedTicket = ticket;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to update ticket status'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _updateTicketPriority(String ticketId, String newPriority) async {
    try {
      final result = await SupportTicketService.updateTicketPriority(ticketId, newPriority);

      if (result['success'] == true) {
        final ticket = result['ticket'] as SupportTicket;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket priority updated to $newPriority'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadData();
        if (_selectedTicket?.id == ticketId) {
          setState(() {
            _selectedTicket = ticket;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to update ticket priority'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _assignTicket(String ticketId, String agentId) async {
    try {
      final result = await SupportTicketService.assignTicket(ticketId, agentId);

      if (result['success'] == true) {
        final ticket = result['ticket'] as SupportTicket;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket assigned to agent $agentId. Status changed to IN_PROGRESS.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadData();
        _loadStatistics();
        if (_selectedTicket?.id == ticketId) {
          setState(() {
            _selectedTicket = ticket;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to assign ticket'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addAgentResponse(String ticketId, String message) async {
    try {
      final result = await SupportTicketService.addAgentResponse(ticketId, message);

      if (result['success'] == true) {
        final ticket = result['ticket'] as SupportTicket;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response added successfully. Ticket status changed to RESOLVED.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _loadData();
        _loadStatistics();
        if (_selectedTicket?.id == ticketId) {
          setState(() {
            _selectedTicket = ticket;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to add response'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openAttachment(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open attachment URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTicketDetail(SupportTicket ticket) async {
    // Reload ticket to get latest data
    final updatedTicket = await SupportTicketService.getTicketById(ticket.id);
    setState(() {
      _selectedTicket = updatedTicket ?? ticket;
      _showDetailPanel = true;
    });
  }

  void _showAssignDialog(SupportTicket ticket) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(width: 8),
            Text(
              'Assign Ticket',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assigning will change ticket status to IN_PROGRESS.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter agent ID to assign this ticket:',
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Agent ID',
                labelStyle: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'Enter agent identifier...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF6366F1), width: 2),
                ),
                prefixIcon: Icon(Icons.person, color: const Color(0xFF6366F1)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _assignTicket(ticket.id, controller.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an agent ID'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              'Assign',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(SupportTicket ticket) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.reply, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(width: 8),
            Text(
              'Add Response',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Adding a response will automatically resolve the ticket.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your response to the customer:',
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Response',
                labelStyle: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'Type your response here...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF6366F1), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _addAgentResponse(ticket.id, controller.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a response'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              'Send Response',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Support Tickets',
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: () {
              _loadData(refresh: true);
              _loadStatistics();
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.inter(color: Colors.grey[700])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadData(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main content area
        Expanded(
          flex: _showDetailPanel ? 2 : 1,
          child: Column(
            children: [
              // Statistics cards
              _buildStatisticsCards(),
              
              // Filters
              _buildFilters(),
              
              // Tickets list
              Expanded(child: _buildTicketsList()),
            ],
          ),
        ),
        
        // Detail panel
        if (_showDetailPanel && _selectedTicket != null)
          Expanded(
            flex: 1,
            child: _buildDetailPanel(_selectedTicket!),
          ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    if (_isLoadingStatistics) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_statistics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total', _statistics!.totalTickets, Colors.blue, Icons.receipt_long),
          const SizedBox(width: 12),
          _buildStatCard('Open', _statistics!.openTickets, Colors.orange, Icons.access_time),
          const SizedBox(width: 12),
          _buildStatCard('In Progress', _statistics!.inProgressTickets, Colors.purple, Icons.hourglass_empty),
          const SizedBox(width: 12),
          _buildStatCard('Resolved', _statistics!.resolvedTickets, Colors.green, Icons.check_circle),
          const SizedBox(width: 12),
          _buildStatCard('Closed', _statistics!.closedTickets, Colors.grey, Icons.lock),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final hasActiveFilters = _selectedStatus != null || 
                            _selectedPriority != null || 
                            (_searchOrderId != null && _searchOrderId!.isNotEmpty) ||
                            (_searchCustomerId != null && _searchCustomerId!.isNotEmpty);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasActiveFilters
              ? [
                  const Color(0xFF6366F1).withOpacity(0.05),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ]
              : [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveFilters
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : Colors.grey.shade200,
          width: hasActiveFilters ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasActiveFilters
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Status filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Icon(
                        Icons.info_outline,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'All Status',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'OPEN',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Open',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'IN_PROGRESS',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'In Progress',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'RESOLVED',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Resolved',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'CLOSED',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Closed',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _loadData(refresh: true);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Priority filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Icon(
                        Icons.flag,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'All Priority',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'LOW',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Low',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'MEDIUM',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Medium',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'HIGH',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'High',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'URGENT',
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Urgent',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value;
                      });
                      _loadData(refresh: true);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Order ID search
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: _orderIdController,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Order ID',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                        fontSize: 13,
                      ),
                      hintText: 'Search by order ID...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.shopping_bag,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _searchOrderId = _orderIdController.text;
                          });
                          _loadData(refresh: true);
                        },
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _searchOrderId = value;
                      });
                      _loadData(refresh: true);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Customer ID search
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: _customerIdController,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Customer ID',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                        fontSize: 13,
                      ),
                      hintText: 'Search by customer ID...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _searchCustomerId = _customerIdController.text;
                          });
                          _loadData(refresh: true);
                        },
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _searchCustomerId = value;
                      });
                      _loadData(refresh: true);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Clear filters button
              Container(
                decoration: BoxDecoration(
                  color: hasActiveFilters
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasActiveFilters
                        ? Colors.red.withOpacity(0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.clear_all,
                    color: hasActiveFilters ? Colors.red : Colors.grey[600],
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedPriority = null;
                      _searchOrderId = null;
                      _searchCustomerId = null;
                      _orderIdController.clear();
                      _customerIdController.clear();
                    });
                    _loadData(refresh: true);
                  },
                  tooltip: 'Clear All Filters',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    if (_ticketsResponse == null || _ticketsResponse!.tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tickets found',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                '${_ticketsResponse!.tickets.length} tickets',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (_ticketsResponse!.totalElements != null)
                Text(
                  'Total: ${_ticketsResponse!.totalElements}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ticketsResponse!.tickets.length,
            itemBuilder: (context, index) {
              final ticket = _ticketsResponse!.tickets[index];
              return _buildTicketCard(ticket);
            },
          ),
        ),
        
        // Pagination
        if (_ticketsResponse!.totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                          _loadData();
                        }
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of ${_ticketsResponse!.totalPages}',
                  style: GoogleFonts.inter(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _ticketsResponse!.totalPages - 1
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                          _loadData();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedTicket?.id == ticket.id
              ? const Color(0xFF6366F1)
              : Colors.grey.shade200,
          width: _selectedTicket?.id == ticket.id ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTicketDetail(ticket),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        ticket.status.replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: priorityColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 12, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            ticket.priority,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Quick actions
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'assign':
                            _showAssignDialog(ticket);
                            break;
                          case 'open':
                            _updateTicketStatus(ticket.id, 'OPEN');
                            break;
                          case 'close':
                            _updateTicketStatus(ticket.id, 'CLOSED');
                            break;
                          case 'respond':
                            _showResponseDialog(ticket);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'assign', child: Text('Assign')),
                        const PopupMenuItem(value: 'respond', child: Text('Add Response')),
                        if (ticket.status != 'OPEN')
                          const PopupMenuItem(value: 'open', child: Text('Reopen')),
                        if (ticket.status != 'CLOSED')
                          const PopupMenuItem(value: 'close', child: Text('Close')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  ticket.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  ticket.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Footer info
                Row(
                  children: [
                    if (ticket.orderId != null) ...[
                      Icon(Icons.shopping_bag, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Order: ${ticket.orderId!.substring(0, 8)}...',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (ticket.hasAttachment) ...[
                      Icon(Icons.attach_file, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Attachment',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (ticket.agentResponse != null) ...[
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Responded',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(SupportTicket ticket) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Color(0xFF6366F1)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ticket Details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showDetailPanel = false;
                      _selectedTicket = null;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Priority
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailCard(
                          'Status',
                          ticket.status.replaceAll('_', ' '),
                          _getStatusColor(ticket.status),
                          Icons.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailCard(
                          'Priority',
                          ticket.priority,
                          _getPriorityColor(ticket.priority),
                          Icons.flag,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.title, color: const Color(0xFF6366F1), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Title',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.grey[700], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Description',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ticket.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Agent Response
                  if (ticket.agentResponse != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade100,
                            Colors.green.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Agent Response',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.agentResponse!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF1F2937),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Attachment
                  if (ticket.hasAttachment) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade100,
                            Colors.blue.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.attach_file, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Attachment',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ticket.attachmentFileName != null)
                                  Row(
                                    children: [
                                      Icon(Icons.insert_drive_file, color: Colors.blue.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ticket.attachmentFileName!,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (ticket.attachmentFileSize != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Size: ${(ticket.attachmentFileSize! / 1024).toStringAsFixed(1)} KB',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _openAttachment(ticket.attachmentFileUrl),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Open Attachment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Metadata
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Ticket Information',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMetadataRow('Ticket ID', ticket.id),
                        const Divider(height: 20),
                        _buildMetadataRow('Customer ID', ticket.customerId),
                        if (ticket.orderId != null) ...[
                          const Divider(height: 20),
                          _buildMetadataRow('Order ID', ticket.orderId!),
                        ],
                        const Divider(height: 20),
                        _buildMetadataRow('Category', ticket.issueCategory.replaceAll('_', ' ')),
                        if (ticket.assignedTo != null) ...[
                          const Divider(height: 20),
                          _buildMetadataRow('Assigned To', ticket.assignedTo!),
                        ],
                        const Divider(height: 20),
                        _buildMetadataRow('Created', _formatDateTime(ticket.createdAt)),
                        if (ticket.updatedAt != null) ...[
                          const Divider(height: 20),
                          _buildMetadataRow('Updated', _formatDateTime(ticket.updatedAt!)),
                        ],
                        if (ticket.resolvedAt != null) ...[
                          const Divider(height: 20),
                          _buildMetadataRow('Resolved', _formatDateTime(ticket.resolvedAt!)),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.05),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.settings, color: const Color(0xFF6366F1), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Actions',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Assign button - only show if not closed
                            if (ticket.status != 'CLOSED')
                              ElevatedButton.icon(
                                onPressed: ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty
                                    ? null
                                    : () => _showAssignDialog(ticket),
                                icon: Icon(
                                  ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty
                                      ? Icons.check_circle
                                      : Icons.person_add,
                                  size: 18,
                                ),
                                label: Text(
                                  ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty
                                      ? 'Assigned'
                                      : 'Assign',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty
                                      ? Colors.grey
                                      : const Color(0xFF1F2937),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            // Respond button - only show if not closed and not already resolved
                            if (ticket.status != 'CLOSED' && ticket.status != 'RESOLVED')
                              ElevatedButton.icon(
                                onPressed: () => _showResponseDialog(ticket),
                                icon: const Icon(Icons.reply, size: 18),
                                label: const Text('Respond'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            // Reopen button - show if closed or resolved
                            if (ticket.status == 'CLOSED' || ticket.status == 'RESOLVED')
                              ElevatedButton.icon(
                                onPressed: () => _updateTicketStatus(ticket.id, 'OPEN'),
                                icon: const Icon(Icons.lock_open, size: 18),
                                label: const Text('Reopen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            // Close button - only show if not already closed
                            if (ticket.status != 'CLOSED')
                              ElevatedButton.icon(
                                onPressed: () => _updateTicketStatus(ticket.id, 'CLOSED'),
                                icon: const Icon(Icons.lock, size: 18),
                                label: const Text('Close'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            // Set to In Progress - show if open
                            if (ticket.status == 'OPEN')
                              ElevatedButton.icon(
                                onPressed: () => _updateTicketStatus(ticket.id, 'IN_PROGRESS'),
                                icon: const Icon(Icons.hourglass_empty, size: 18),
                                label: const Text('Set In Progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Priority change
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Change Priority',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((priority) {
                            final isSelected = ticket.priority == priority;
                            final priorityColor = _getPriorityColor(priority);
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? priorityColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Icon(Icons.check_circle, size: 16, color: Colors.white),
                                    if (isSelected) const SizedBox(width: 6),
                                    Text(
                                      priority,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : priorityColor,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected && !isSelected) {
                                    _updateTicketPriority(ticket.id, priority);
                                  }
                                },
                                selectedColor: priorityColor,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.red;
      case 'URGENT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

