import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';
import 'analytics_detail_screens.dart';

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Insights
          _buildBusinessInsights(),
          const SizedBox(height: 20),
          
          // Key Metrics
          _buildSectionTitle('Key Metrics'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 4.4,
            children: [
              _buildUsersCard(),
              _buildVendorsCard(),
              _buildOrdersCard(),
              _buildRevenueCard(),
            ],
          ),
          const SizedBox(height: 20),
          
          // Additional Metrics
          _buildSectionTitle('Additional Metrics'),
          const SizedBox(height: 12),
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

  Widget _buildUsersCard() {
    return InkWell(
      onTap: () => _navigateToDetail('users', 'User Statistics'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.people, color: Color(0xFF3B82F6), size: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Users',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: const Color(0xFF9CA3AF), size: 10),
              ],
            ),
            const SizedBox(height: 4),
            _buildCompactStatRow(Icons.people_outline, 'Total', '${_analytics!.users.total}', const Color(0xFF6B7280)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.person, 'Active', '${_analytics!.users.active}', const Color(0xFF10B981)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.verified_user, 'Verified', '${_analytics!.users.verified}', const Color(0xFF3B82F6)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.person_off, 'Inactive', '${_analytics!.users.inactive}', const Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsCard() {
    return InkWell(
      onTap: () => _navigateToDetail('vendors', 'Vendor Statistics'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.store, color: Color(0xFF8B5CF6), size: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vendors',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: const Color(0xFF9CA3AF), size: 10),
              ],
            ),
            const SizedBox(height: 4),
            _buildCompactStatRow(Icons.store, 'Total', '${_analytics!.vendors.total}', const Color(0xFF6B7280)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.check_circle, 'Approved', '${_analytics!.vendors.approved}', const Color(0xFF10B981)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.pending, 'Pending', '${_analytics!.vendors.pending}', const Color(0xFFF59E0B)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.store_mall_directory, 'Open', '${_analytics!.vendors.open}', const Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    return InkWell(
      onTap: () => _navigateToDetail('orders', 'Order Statistics'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.shopping_cart, color: Color(0xFFF59E0B), size: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Orders',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: const Color(0xFF9CA3AF), size: 10),
              ],
            ),
            const SizedBox(height: 4),
            _buildCompactStatRow(Icons.shopping_cart, 'Total', '${_analytics!.orders.total}', const Color(0xFF6B7280)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.check_circle, 'Completed', '${_analytics!.orders.completed}', const Color(0xFF10B981)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.pending, 'Pending', '${_analytics!.orders.pending}', const Color(0xFFF59E0B)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.today, 'Today', '${_analytics!.orders.today}', const Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return InkWell(
      onTap: () => _navigateToDetail('revenue', 'Revenue Overview'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Revenue',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: const Color(0xFF9CA3AF), size: 10),
              ],
            ),
            const SizedBox(height: 4),
            _buildCompactStatRow(Icons.account_balance, 'Total', _formatCurrency(_analytics!.revenue.total), const Color(0xFF10B981)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.calendar_month, 'This Month', _formatCurrency(_analytics!.revenue.thisMonth), const Color(0xFF6366F1)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.today, 'Today', _formatCurrency(_analytics!.revenue.today), const Color(0xFFF59E0B)),
            const SizedBox(height: 2),
            _buildCompactStatRow(Icons.trending_up, 'Avg Order', _formatCurrency(_calculateAOV()), const Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _calculateAOV() {
    if (_analytics!.orders.completed == 0) return 0;
    return _analytics!.revenue.total / _analytics!.orders.completed;
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


  
  String _getMetricType(String title) {
    if (title.contains('User')) return 'users';
    if (title.contains('Vendor')) return 'vendors';
    if (title.contains('Order')) return 'orders';
    return 'general';
  }
  
  void _navigateToDetail(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDetailScreen(
          type: type,
          title: title,
          analytics: _analytics!,
        ),
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
    return InkWell(
      onTap: () => _navigateToDetail(_getInfoCardType(title), title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: const Color(0xFF9CA3AF), size: 12),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getInfoCardType(String title) {
    if (title.contains('Medicine')) return 'medicines';
    if (title.contains('Document')) return 'documents';
    if (title.contains('Manager')) return 'managers';
    return 'general';
  }

  Widget _buildBusinessInsights() {
    final completionRate = _analytics!.orders.total > 0
        ? (_analytics!.orders.completed / _analytics!.orders.total * 100)
        : 0.0;
    final approvalRate = _analytics!.vendors.total > 0
        ? (_analytics!.vendors.approved / _analytics!.vendors.total * 100)
        : 0.0;
    final aov = _analytics!.orders.completed > 0
        ? (_analytics!.revenue.total / _analytics!.orders.completed)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights, color: Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Business Performance Insights',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'Order Completion Rate',
                  '${completionRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightCard(
                  'Vendor Approval Rate',
                  '${approvalRate.toStringAsFixed(1)}%',
                  Icons.verified,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightCard(
                  'Avg Order Value',
                  _formatCurrency(aov),
                  Icons.receipt,
                  const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 12,
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

