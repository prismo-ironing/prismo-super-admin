import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  AnalyticsOverview? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = await AnalyticsService.getAnalyticsOverview();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
              child: const Icon(Icons.analytics, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Business Analytics',
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
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _analytics == null
                  ? const Center(child: Text('No data available'))
                  : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Overview Cards
          _buildSectionTitle('Revenue Overview'),
          const SizedBox(height: 16),
          _buildRevenueCards(),
          const SizedBox(height: 32),
          
          // Key Metrics Grid
          _buildSectionTitle('Key Metrics'),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 32),
          
          // Vendor Statistics
          _buildSectionTitle('Vendor Statistics'),
          const SizedBox(height: 16),
          _buildVendorStats(),
          const SizedBox(height: 32),
          
          // Order Statistics
          _buildSectionTitle('Order Statistics'),
          const SizedBox(height: 16),
          _buildOrderStats(),
          const SizedBox(height: 32),
          
          // Additional Metrics
          _buildSectionTitle('Additional Metrics'),
          const SizedBox(height: 16),
          _buildAdditionalMetrics(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: const Color(0xFF1F2937),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRevenueCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            _formatCurrency(_analytics!.revenue.total),
            Icons.account_balance_wallet,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'This Month',
            _formatCurrency(_analytics!.revenue.thisMonth),
            Icons.calendar_today,
            const Color(0xFF6366F1),
            const Color(0xFFE0E7FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Today',
            _formatCurrency(_analytics!.revenue.today),
            Icons.today,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Users',
          '${_analytics!.users.total}',
          Icons.people,
          const Color(0xFF3B82F6),
        ),
        _buildMetricCard(
          'Active Users',
          '${_analytics!.users.active}',
          Icons.person,
          const Color(0xFF10B981),
        ),
        _buildMetricCard(
          'Total Vendors',
          '${_analytics!.vendors.total}',
          Icons.store,
          const Color(0xFF8B5CF6),
        ),
        _buildMetricCard(
          'Approved Vendors',
          '${_analytics!.vendors.approved}',
          Icons.verified,
          const Color(0xFF10B981),
        ),
        _buildMetricCard(
          'Total Orders',
          '${_analytics!.orders.total}',
          Icons.shopping_cart,
          const Color(0xFFF59E0B),
        ),
        _buildMetricCard(
          'Completed Orders',
          '${_analytics!.orders.completed}',
          Icons.check_circle,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildVendorStats() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          _buildStatRow('Total Vendors', '${_analytics!.vendors.total}', Icons.store),
          const Divider(),
          _buildStatRow('Approved', '${_analytics!.vendors.approved}', Icons.check_circle, Colors.green),
          _buildStatRow('Pending Review', '${_analytics!.vendors.pending}', Icons.pending, Colors.orange),
          _buildStatRow('Rejected', '${_analytics!.vendors.rejected}', Icons.cancel, Colors.red),
          const Divider(),
          _buildStatRow('Verified', '${_analytics!.vendors.verified}', Icons.verified, Colors.blue),
          _buildStatRow('Open Stores', '${_analytics!.vendors.open}', Icons.store_mall_directory, Colors.green),
          _buildStatRow('Closed Stores', '${_analytics!.vendors.closed}', Icons.store_mall_directory_outlined, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildOrderStats() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          _buildStatRow('Total Orders', '${_analytics!.orders.total}', Icons.shopping_cart),
          const Divider(),
          _buildStatRow('Completed', '${_analytics!.orders.completed}', Icons.check_circle, Colors.green),
          _buildStatRow('Pending', '${_analytics!.orders.pending}', Icons.pending, Colors.orange),
          _buildStatRow('In Progress', '${_analytics!.orders.inProgress}', Icons.hourglass_empty, Colors.blue),
          _buildStatRow('Cancelled', '${_analytics!.orders.cancelled}', Icons.cancel, Colors.red),
          const Divider(),
          _buildStatRow('Today\'s Orders', '${_analytics!.orders.today}', Icons.today, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildAdditionalMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Medicines',
            '${_analytics!.medicines.total} Total\n${_analytics!.medicines.active} Active\n${_analytics!.medicines.inventoryItems} Inventory Items',
            Icons.medication,
            const Color(0xFFEC4899),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'Documents',
            '${_analytics!.documents.total} Total\n${_analytics!.documents.approved} Approved\n${_analytics!.documents.pending} Pending',
            Icons.description,
            const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'Managers',
            '${_analytics!.managers.total} Total\n${_analytics!.managers.active} Active\n${_analytics!.managers.inactive} Inactive',
            Icons.people_outline,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color ?? const Color(0xFF6B7280), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }
}

