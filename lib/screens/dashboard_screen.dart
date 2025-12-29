import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/manager.dart';
import '../models/store.dart';
import '../models/vendor_document.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Manager> _managers = [];
  List<Store> _stores = [];
  bool _isLoading = true;
  String? _error;
  Manager? _selectedManager;
  Store? _selectedStoreForDocuments;
  VendorActivationStatus? _vendorActivationStatus;
  bool _isLoadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAllManagers(),
        ApiService.getAllStores(),
      ]);

      setState(() {
        _managers = results[0] as List<Manager>;
        _stores = results[1] as List<Store>;
        _isLoading = false;
        
        // Update selected manager with fresh data
        if (_selectedManager != null) {
          _selectedManager = _managers.firstWhere(
            (m) => m.id == _selectedManager!.id,
            orElse: () => _selectedManager!,
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('super_admin_auth');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _assignStore(Manager manager, Store store) async {
    final success = await ApiService.assignStoreToManager(manager.id, store.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned ${store.name} to ${manager.name}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to assign store'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeStore(Manager manager, String storeId) async {
    final store = _stores.firstWhere((s) => s.id == storeId, orElse: () => Store(id: storeId, name: storeId));
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        title: Text('Remove Store', style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
          'Remove "${store.name}" from ${manager.name}?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.removeStoreFromManager(manager.id, storeId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${store.name} from ${manager.name}'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
      }
    }
  }

  // Find current manager for a store
  Manager? _findCurrentManager(String storeId) {
    for (final m in _managers) {
      if (m.vendorIds.contains(storeId)) {
        return m;
      }
    }
    return null;
  }

  // Load vendor documents for review
  Future<void> _loadVendorDocuments(Store store) async {
    setState(() {
      _selectedStoreForDocuments = store;
      _isLoadingDocuments = true;
      _vendorActivationStatus = null;
    });

    final status = await ApiService.getVendorActivationStatus(store.id);
    
    setState(() {
      _vendorActivationStatus = status;
      _isLoadingDocuments = false;
    });
  }

  // Approve a document
  Future<void> _approveDocument(VendorDocument doc) async {
    final success = await ApiService.approveDocument(
      doc.vendorId, 
      doc.id,
      comments: 'Approved by Super Admin',
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.displayType} approved'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload documents
      if (_selectedStoreForDocuments != null) {
        _loadVendorDocuments(_selectedStoreForDocuments!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reject a document
  Future<void> _rejectDocument(VendorDocument doc, String reason) async {
    final success = await ApiService.rejectDocument(
      doc.vendorId, 
      doc.id,
      comments: reason,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.displayType} rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      // Reload documents
      if (_selectedStoreForDocuments != null) {
        _loadVendorDocuments(_selectedStoreForDocuments!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Approve vendor activation
  Future<void> _approveVendorActivation() async {
    if (_selectedStoreForDocuments == null) return;
    
    final success = await ApiService.approveVendorActivation(_selectedStoreForDocuments!.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vendor ${_selectedStoreForDocuments!.name} activated!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload documents and data
      _loadVendorDocuments(_selectedStoreForDocuments!);
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve vendor. Ensure all documents are approved.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reject vendor activation
  Future<void> _rejectVendorActivation() async {
    if (_selectedStoreForDocuments == null) return;
    
    final controller = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'Reject Vendor Activation',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rejection reason...',
                hintStyle: GoogleFonts.inter(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reject', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
    
    if (reason != null) {
      final success = await ApiService.rejectVendorActivation(
        _selectedStoreForDocuments!.id,
        reason: reason.isEmpty ? 'Vendor activation rejected by Super Admin' : reason,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor ${_selectedStoreForDocuments!.name} rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        // Reload documents and data
        _loadVendorDocuments(_selectedStoreForDocuments!);
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject vendor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show rejection dialog
  Future<void> _showRejectDialog(VendorDocument doc) async {
    final controller = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 12),
            Text('Reject ${doc.displayType}', style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: GoogleFonts.inter(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0f3460),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      _rejectDocument(doc, reason);
    }
  }

  // Open document via download URL
  Future<void> _openDocument(VendorDocument doc) async {
    // First, get a signed download URL from the backend
    final downloadUrl = await ApiService.getDocumentDownloadUrl(doc.vendorId, doc.id);
    
    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get document URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Show transfer confirmation dialog
  Future<bool> _showTransferConfirmation(Store store, Manager currentManager, Manager newManager) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz, color: Colors.orange),
            const SizedBox(width: 12),
            Text('Transfer Store?', style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${store.name}" is currently assigned to ${currentManager.name}.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'Transfer to ${newManager.name}?',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Transfer', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAssignStoreDialog(Manager manager) {
    // Get stores not already assigned to THIS manager
    final availableStores = _stores.where((s) => !manager.vendorIds.contains(s.id)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        title: Row(
          children: [
            const Icon(Icons.add_business, color: Color(0xFFe94560)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Assign Store to ${manager.name}', 
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: availableStores.isEmpty
              ? Center(
                  child: Text(
                    'No stores available to assign',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: availableStores.length,
                  itemBuilder: (context, index) {
                    final store = availableStores[index];
                    final currentManager = _findCurrentManager(store.id);
                    final isAssigned = currentManager != null;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAssigned ? Colors.orange.withOpacity(0.1) : const Color(0xFF0f3460).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isAssigned ? Colors.orange.withOpacity(0.3) : Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isAssigned ? Colors.orange.withOpacity(0.2) : const Color(0xFF0f3460),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.store, 
                              color: isAssigned ? Colors.orange : Colors.white70, 
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name, 
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  store.id,
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white38, 
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isAssigned)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '⚠️ Assigned to: ${currentManager.name}',
                                      style: GoogleFonts.inter(
                                        color: Colors.orange.withOpacity(0.8), 
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isAssigned ? Icons.swap_horiz : Icons.add_circle, 
                              color: isAssigned ? Colors.orange : const Color(0xFF4CAF50),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              if (isAssigned) {
                                final confirmed = await _showTransferConfirmation(store, currentManager, manager);
                                if (confirmed) {
                                  _assignStore(manager, store);
                                }
                              } else {
                                _assignStore(manager, store);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFe94560), Color(0xFFff6b6b)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Prismo Super Admin',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFe94560)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.inter(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final showDocPanel = _selectedStoreForDocuments != null;
    
    return Row(
      children: [
        // Left Panel - Managers List
        Expanded(
          flex: showDocPanel ? 2 : 2,
          child: _buildManagersPanel(),
        ),
        // Middle Panel - Selected Manager Details
        Expanded(
          flex: showDocPanel ? 2 : 3,
          child: _selectedManager != null
              ? _buildManagerDetails(_selectedManager!)
              : _buildNoSelectionPlaceholder(),
        ),
        // Right Panel - Document Review
        if (showDocPanel)
          Expanded(
            flex: 3,
            child: _buildDocumentReviewPanel(),
          ),
      ],
    );
  }

  Widget _buildManagersPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.people, color: Color(0xFFe94560)),
                const SizedBox(width: 12),
                Text(
                  'Managers',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe94560).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_managers.length}',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFe94560),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _managers.length,
              itemBuilder: (context, index) {
                final manager = _managers[index];
                final isSelected = _selectedManager?.id == manager.id;
                return _buildManagerListTile(manager, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerListTile(Manager manager, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFe94560).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: const Color(0xFFe94560).withOpacity(0.5)) 
            : null,
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedManager = manager),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? const Color(0xFFe94560) : const Color(0xFF0f3460),
              child: Text(
                manager.name.isNotEmpty ? manager.name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    manager.phoneNumber,
                    style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: manager.vendorIds.isEmpty 
                    ? Colors.orange.withOpacity(0.2) 
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${manager.vendorIds.length}',
                style: GoogleFonts.robotoMono(
                  color: manager.vendorIds.isEmpty ? Colors.orange : Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Select a manager to view details',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerDetails(Manager manager) {
    final assignedStores = _stores.where((s) => manager.vendorIds.contains(s.id)).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manager Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFe94560).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFe94560),
                  child: Text(
                    manager.name.isNotEmpty ? manager.name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(Icons.phone, manager.phoneNumber),
                          _buildInfoChip(
                            Icons.verified_user,
                            manager.role,
                            color: manager.isAdmin ? Colors.amber : Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAssignStoreDialog(manager),
                  icon: const Icon(Icons.add_business, size: 18),
                  label: const Text('Assign Store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
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
          
          const Divider(color: Colors.white10, height: 1),
          
          // Manager Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStatCard('ID', manager.id, Icons.fingerprint),
                const SizedBox(width: 16),
                _buildStatCard('Email', manager.email ?? 'Not set', Icons.email),
                const SizedBox(width: 16),
                _buildStatCard('Stores', '${manager.vendorIds.length}', Icons.store),
              ],
            ),
          ),
          
          // Assigned Stores Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.store, color: Color(0xFFe94560), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Assigned Stores',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: assignedStores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory_outlined, 
                            size: 48, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No stores assigned',
                          style: GoogleFonts.inter(color: Colors.white38),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAssignStoreDialog(manager),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Assign a store'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFe94560),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: assignedStores.length,
                    itemBuilder: (context, index) {
                      final store = assignedStores[index];
                      return _buildAssignedStoreCard(manager, store);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color color = Colors.white54}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.robotoMono(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0f3460).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.white38),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedStoreCard(Manager manager, Store store) {
    final isSelected = _selectedStoreForDocuments?.id == store.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFe94560).withOpacity(0.15)
            : const Color(0xFF0f3460).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFFe94560).withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.store, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.id,
                  style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _loadVendorDocuments(store),
            icon: const Icon(Icons.fact_check_outlined, color: Color(0xFF64B5F6)),
            tooltip: 'Review Documents',
          ),
          IconButton(
            onPressed: () => _removeStore(manager, store.id),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            tooltip: 'Remove store',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentReviewPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF64B5F6).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check, color: Color(0xFF64B5F6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Review',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedStoreForDocuments?.name ?? '',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _selectedStoreForDocuments = null;
                    _vendorActivationStatus = null;
                  }),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white10, height: 1),
          
          // Content
          Expanded(
            child: _isLoadingDocuments
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
                  )
                : _vendorActivationStatus == null
                    ? Center(
                        child: Text(
                          'No activation data found',
                          style: GoogleFonts.inter(color: Colors.white38),
                        ),
                      )
                    : _buildDocumentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    final status = _vendorActivationStatus!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activation Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status.activationStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(status.activationStatus).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status.activationStatus),
                  color: _getStatusColor(status.activationStatus),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${status.activationStatus}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Approved: ${status.approvedDocuments}/${status.totalRequiredDocuments} required',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Always show approve/reject buttons for full control
                Row(
                  children: [
                    // Always show approve button (enabled for full control)
                    ElevatedButton.icon(
                      onPressed: _approveVendorActivation,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(status.activationStatus == 'APPROVED' 
                          ? 'Re-approve Vendor' 
                          : 'Approve Vendor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Always show reject button (enabled for full control)
                    OutlinedButton.icon(
                      onPressed: _rejectVendorActivation,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: Text(status.activationStatus == 'REJECTED'
                          ? 'Reject Again'
                          : 'Reject Vendor'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Documents (${status.documents.length})',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Documents List
          ...status.documents.map((doc) => _buildDocumentCard(doc)),
          
          if (status.documents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'No documents uploaded yet',
                      style: GoogleFonts.inter(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(VendorDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: doc.isApproved
              ? Colors.green.withOpacity(0.3)
              : doc.isRejected
                  ? Colors.red.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: doc.isApproved
                      ? Colors.green.withOpacity(0.2)
                      : doc.isRejected
                          ? Colors.red.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  doc.isApproved
                      ? Icons.check_circle
                      : doc.isRejected
                          ? Icons.cancel
                          : Icons.pending,
                  color: doc.isApproved
                      ? Colors.green
                      : doc.isRejected
                          ? Colors.red
                          : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.displayType,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Status: ${doc.documentStatus}',
                      style: GoogleFonts.inter(
                        color: doc.isApproved
                            ? Colors.green
                            : doc.isRejected
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openDocument(doc),
                icon: const Icon(Icons.open_in_new, color: Color(0xFF64B5F6)),
                tooltip: 'View Document',
              ),
            ],
          ),
          
          if (doc.documentNumber != null || doc.documentName != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            if (doc.documentNumber != null)
              _buildDocumentDetail('Number', doc.documentNumber!),
            if (doc.documentName != null)
              _buildDocumentDetail('Name', doc.documentName!),
          ],
          
          if (doc.reviewerComments != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment, size: 14, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.reviewerComments!,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Action Buttons (always visible for full control)
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Show reject button if not already rejected
              if (!doc.isRejected)
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(doc),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              // Show approve button if not already approved
              if (!doc.isApproved) ...[
                if (!doc.isRejected)
                  const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _approveDocument(doc),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'DOCUMENTS_SUBMITTED':
      case 'UNDER_REVIEW':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.verified;
      case 'REJECTED':
        return Icons.cancel;
      case 'DOCUMENTS_SUBMITTED':
      case 'UNDER_REVIEW':
        return Icons.pending_actions;
      default:
        return Icons.info;
    }
  }
}

