import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/store_statistics.dart';
import '../models/store.dart';
import '../services/api_service.dart';

class StoreStatisticsScreen extends StatefulWidget {
  final Store store;

  const StoreStatisticsScreen({
    super.key,
    required this.store,
  });

  @override
  State<StoreStatisticsScreen> createState() => _StoreStatisticsScreenState();
}

class _StoreStatisticsScreenState extends State<StoreStatisticsScreen> {
  StoreStatistics? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await ApiService.getStoreStatistics(widget.store.id);
      setState(() {
        _statistics = stats;
        _isLoading = false;
        if (stats == null) {
          _error = 'Failed to load store statistics';
        }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
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
              child: const Icon(Icons.store, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.name,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Business Statistics',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
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
                        onPressed: _loadStatistics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _statistics == null
                  ? const Center(
                      child: Text('No statistics available'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Info Card
                          _buildStoreInfoCard(),
                          const SizedBox(height: 16),
                          
                          // Revenue Section
                          _buildSectionTitle('Revenue Statistics', Icons.attach_money),
                          const SizedBox(height: 12),
                          _buildRevenueCards(),
                          const SizedBox(height: 24),
                          
                          // Order Statistics
                          _buildSectionTitle('Order Statistics', Icons.shopping_cart),
                          const SizedBox(height: 12),
                          _buildOrderCards(),
                          const SizedBox(height: 24),
                          
                          // Rating Statistics
                          _buildSectionTitle('Rating Statistics', Icons.star),
                          const SizedBox(height: 12),
                          _buildRatingCards(),
                          const SizedBox(height: 24),
                          
                          // Performance Metrics
                          _buildSectionTitle('Performance Metrics', Icons.trending_up),
                          const SizedBox(height: 12),
                          _buildPerformanceCards(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStoreInfoCard() {
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.store.name,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.store.id,
                  style: GoogleFonts.robotoMono(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                if (widget.store.displayLocation != 'Location N/A') ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.store.displayLocation,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            _formatCurrency(_statistics!.totalRevenue),
            Icons.account_balance_wallet,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'This Month',
            _formatCurrency(_statistics!.thisMonthRevenue),
            Icons.calendar_month,
            const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Today',
            _formatCurrency(_statistics!.todayRevenue),
            Icons.today,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Orders',
                '${_statistics!.totalOrders}',
                Icons.receipt_long,
                const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${_statistics!.completedOrders}',
                Icons.check_circle,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                '${_statistics!.pendingOrders}',
                Icons.pending,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Cancelled',
                '${_statistics!.cancelledOrders}',
                Icons.cancel,
                const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Accepted',
                '${_statistics!.acceptedOrders}',
                Icons.thumb_up,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rejected',
                '${_statistics!.rejectedOrders}',
                Icons.thumb_down,
                const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Order Value',
                _formatCurrency(_statistics!.averageOrderValue),
                Icons.attach_money,
                const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Charges/Order',
                _formatCurrency(_statistics!.chargesPerOrder),
                Icons.payment,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average Rating',
            _statistics!.totalRatings > 0
                ? '${_statistics!.averageRating.toStringAsFixed(2)} ⭐'
                : 'N/A',
            Icons.star,
            const Color(0xFFF59E0B),
            subtitle: '${_statistics!.totalRatings} ratings',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Delivery Rating',
            _statistics!.averageDeliveryRating > 0
                ? '${_statistics!.averageDeliveryRating.toStringAsFixed(2)} ⭐'
                : 'N/A',
            Icons.local_shipping,
            const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Product Rating',
            _statistics!.averageProductRating > 0
                ? '${_statistics!.averageProductRating.toStringAsFixed(2)} ⭐'
                : 'N/A',
            Icons.inventory_2,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Acceptance Rate',
            '${_statistics!.acceptanceRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rejection Rate',
            '${_statistics!.rejectionRate.toStringAsFixed(1)}%',
            Icons.trending_down,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completion Rate',
            '${_statistics!.completionRate.toStringAsFixed(1)}%',
            Icons.check_circle_outline,
            const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 20,
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}

