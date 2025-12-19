import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manager.dart';
import '../models/store.dart';
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

  void _showAssignStoreDialog(Manager manager) {
    final unassignedStores = _stores.where((s) => !manager.vendorIds.contains(s.id)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        title: Row(
          children: [
            const Icon(Icons.add_business, color: Color(0xFFe94560)),
            const SizedBox(width: 12),
            Text('Assign Store to ${manager.name}', 
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: unassignedStores.isEmpty
              ? Center(
                  child: Text(
                    'All stores are already assigned',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: unassignedStores.length,
                  itemBuilder: (context, index) {
                    final store = unassignedStores[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f3460),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store, color: Colors.white70, size: 20),
                      ),
                      title: Text(store.name, style: GoogleFonts.inter(color: Colors.white)),
                      subtitle: Text(store.id, style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF4CAF50)),
                        onPressed: () {
                          Navigator.pop(context);
                          _assignStore(manager, store);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _assignStore(manager, store);
                      },
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
    return Row(
      children: [
        // Left Panel - Managers List
        Expanded(
          flex: 2,
          child: _buildManagersPanel(),
        ),
        // Right Panel - Selected Manager Details
        Expanded(
          flex: 3,
          child: _selectedManager != null
              ? _buildManagerDetails(_selectedManager!)
              : _buildNoSelectionPlaceholder(),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFe94560).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: const Color(0xFFe94560).withOpacity(0.5)) 
            : null,
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedManager = manager),
        leading: CircleAvatar(
          backgroundColor: isSelected ? const Color(0xFFe94560) : const Color(0xFF0f3460),
          child: Text(
            manager.name.isNotEmpty ? manager.name[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          manager.name,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          manager.phoneNumber,
          style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: manager.vendorIds.isEmpty 
                ? Colors.orange.withOpacity(0.2) 
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${manager.vendorIds.length} stores',
            style: GoogleFonts.robotoMono(
              color: manager.vendorIds.isEmpty ? Colors.orange : Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                      Row(
                        children: [
                          _buildInfoChip(Icons.phone, manager.phoneNumber),
                          const SizedBox(width: 12),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
            onPressed: () => _removeStore(manager, store.id),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            tooltip: 'Remove store',
          ),
        ],
      ),
    );
  }
}

