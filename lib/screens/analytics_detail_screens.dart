import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../models/store.dart';
import '../models/manager.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'store_statistics_screen.dart';

class AnalyticsDetailScreen extends StatefulWidget {
  final String type;
  final String title;
  final AnalyticsOverview analytics;

  const AnalyticsDetailScreen({
    super.key,
    required this.type,
    required this.title,
    required this.analytics,
  });

  @override
  State<AnalyticsDetailScreen> createState() => _AnalyticsDetailScreenState();
}

class _AnalyticsDetailScreenState extends State<AnalyticsDetailScreen> {
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
  List<Store> _stores = [];
  List<Manager> _managers = [];
  bool _isLoading = true;
  
  // User list state
  List<User> _users = [];
  List<User> _filteredUsers = [];
  String _searchQuery = '';
  String _sortBy = 'createdAt';
  bool _sortAsc = false;
  bool _isLoadingUsers = false;
  bool _isLoadingMore = false;
  
  // Vendor list state
  List<Store> _filteredStores = [];
  String _vendorSearchQuery = '';
  String _vendorSortBy = 'name';
  bool _vendorSortAsc = true;
  
  // Order counts map (userId -> orderCount)
  Map<String, int> _userOrderCounts = {};
  
  // Order list state (for orders type)
  List<Map<String, dynamic>> _orders = [];
  Map<String, Map<String, dynamic>> _orderRatings = {}; // orderId -> rating data
  bool _isLoadingOrders = false;
  bool _isLoadingMoreOrders = false;
  double? _averageRating;
  int _totalRatedOrders = 0;
  final ScrollController _orderScrollController = ScrollController();
  
  // Pagination
  static const int _pageSize = 50;
  int _currentPage = 0;
  int _totalElements = 0;
  int _totalPages = 0;
  bool get _hasMoreItems => _currentPage < _totalPages - 1;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _vendorScrollController = ScrollController();
  
  // Search debounce timer
  Timer? _searchDebounceTimer;
  Timer? _vendorSearchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.type == 'users') {
      _scrollController.addListener(_onScroll);
      _loadUsers();
    } else if (widget.type == 'vendors') {
      _vendorScrollController.addListener(_onVendorScroll);
      // Apply initial filter after stores are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyVendorFilters();
      });
    } else if (widget.type == 'orders') {
      _orderScrollController.addListener(_onOrderScroll);
      _loadOrders();
    }
  }
  
  @override
  void dispose() {
    if (widget.type == 'users') {
      _scrollController.dispose();
      _searchDebounceTimer?.cancel();
    } else if (widget.type == 'vendors') {
      _vendorScrollController.dispose();
      _vendorSearchDebounceTimer?.cancel();
    } else if (widget.type == 'orders') {
      _orderScrollController.dispose();
    }
    super.dispose();
  }
  
  void _onVendorScroll() {
    // Can add pagination later if needed
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreItems && !_isLoadingUsers && !_isLoadingMore) {
        _loadMoreUsers();
      }
    }
  }
  
  void _onOrderScroll() {
    if (_orderScrollController.position.pixels >= _orderScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingOrders && !_isLoadingMoreOrders && _orders.length < _totalElements) {
        _loadMoreOrders();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAllStores(),
        ApiService.getAllManagers(),
      ]);
      setState(() {
        _stores = results[0] as List<Store>;
        _managers = results[1] as List<Manager>;
        _isLoading = false;
      });
      
      // Apply initial filters for vendors
      if (widget.type == 'vendors') {
        _applyVendorFilters();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case 'revenue':
        return const Color(0xFF10B981);
      case 'users':
        return const Color(0xFF3B82F6);
      case 'vendors':
        return const Color(0xFF8B5CF6);
      case 'orders':
        return const Color(0xFFF59E0B);
      case 'medicines':
        return const Color(0xFFEC4899);
      case 'documents':
        return const Color(0xFF06B6D4);
      case 'managers':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case 'revenue':
        return Icons.account_balance_wallet;
      case 'users':
        return Icons.people;
      case 'vendors':
        return Icons.store;
      case 'orders':
        return Icons.shopping_cart;
      case 'medicines':
        return Icons.medication;
      case 'documents':
        return Icons.description;
      case 'managers':
        return Icons.people_outline;
      default:
        return Icons.analytics;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();
    
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
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getTypeIcon(), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.type == 'users'
              ? _buildScrollableUserContent(typeColor)
              : widget.type == 'vendors'
                  ? _buildScrollableVendorContent(typeColor)
                  : widget.type == 'orders'
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _buildFilters(typeColor),
                              Expanded(child: _buildContent(typeColor)),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (widget.type != 'users' && widget.type != 'vendors') _buildFilters(typeColor),
                            Expanded(child: _buildContent(typeColor)),
                          ],
                        ),
    );
  }

  Widget _buildFilters(Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor, width: 1.5),
              ),
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.filter_list, color: typeColor, size: 20),
                dropdownColor: Colors.white,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: _getFilterOptions().map((option) {
                  final isSelected = option['value'] == _selectedFilter;
                  return DropdownMenuItem(
                    value: option['value']!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? typeColor.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        option['label']!,
                        style: GoogleFonts.inter(
                          color: isSelected ? typeColor : const Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                  if (widget.type == 'users') {
                    _applyFilters();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: typeColor, width: 1.5),
            ),
            child: IconButton(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(
                          primary: typeColor,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                }
              },
              icon: Icon(Icons.calendar_today, color: typeColor, size: 20),
              tooltip: 'Select Date Range',
            ),
          ),
          if (_dateRange != null) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6B7280), width: 1.5),
              ),
              child: IconButton(
                onPressed: () => setState(() => _dateRange = null),
                icon: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 20),
                tooltip: 'Clear Date Range',
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, String>> _getFilterOptions() {
    switch (widget.type) {
      case 'vendors':
        return [
          {'value': 'all', 'label': 'All Vendors'},
          {'value': 'active', 'label': 'Active'},
          {'value': 'inactive', 'label': 'Inactive'},
        ];
      case 'orders':
        return [
          {'value': 'all', 'label': 'All Orders'},
          {'value': 'completed', 'label': 'Completed'},
          {'value': 'pending', 'label': 'Pending'},
          {'value': 'cancelled', 'label': 'Cancelled'},
        ];
      case 'users':
        return [
          {'value': 'all', 'label': 'All Users'},
          {'value': 'active', 'label': 'Has Orders'},
          {'value': 'inactive', 'label': 'No Orders'},
        ];
      default:
        return [{'value': 'all', 'label': 'All'}];
    }
  }

  Widget _buildContent(Color typeColor) {
    if (widget.type == 'users') {
      // For users, use a different layout with scrollable list
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsights(typeColor),
            const SizedBox(height: 24),
            Expanded(child: _buildDataList(typeColor)),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsights(typeColor),
          const SizedBox(height: 24),
          _buildDataList(typeColor),
        ],
      ),
    );
  }

  Widget _buildInsights(Color typeColor) {
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
              Icon(Icons.insights, color: typeColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Business Insights',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._getInsights(typeColor),
        ],
      ),
    );
  }

  List<Widget> _getInsights(Color typeColor) {
    switch (widget.type) {
      case 'revenue':
        return [
          _buildInsightItem(
            'Total Revenue',
            _formatCurrency(widget.analytics.revenue.total),
            typeColor,
            Icons.account_balance_wallet,
            description: 'Cumulative revenue from all completed orders',
          ),
          _buildInsightItem(
            'This Month Revenue',
            _formatCurrency(widget.analytics.revenue.thisMonth),
            typeColor,
            Icons.calendar_month,
            description: 'Total revenue generated in the current month',
          ),
          _buildInsightItem(
            "Today's Revenue",
            _formatCurrency(widget.analytics.revenue.today),
            typeColor,
            Icons.today,
            description: 'Revenue generated today from completed orders',
          ),
          _buildInsightItem(
            'Revenue Growth',
            _calculateRevenueGrowth(),
            typeColor,
            Icons.trending_up,
            description: _getRevenueGrowthDescription(),
          ),
          _buildInsightItem(
            'Average Order Value',
            _formatCurrency(_calculateAOV()),
            typeColor,
            Icons.receipt,
            description: 'Average amount per completed order (Total Revenue ÷ Completed Orders)',
          ),
          _buildInsightItem(
            'Daily Average (This Month)',
            _formatCurrency(_calculateDailyAverage()),
            typeColor,
            Icons.show_chart,
            description: 'Average daily revenue for the current month',
          ),
          _buildInsightItem(
            'Monthly Projection',
            _formatCurrency(_calculateMonthlyProjection()),
            typeColor,
            Icons.timeline,
            description: 'Projected monthly revenue based on today\'s performance',
          ),
        ];
      case 'vendors':
        return [
          _buildInsightItem(
            'Approval Rate',
            '${_calculateApprovalRate().toStringAsFixed(2)}%',
            typeColor,
            Icons.check_circle,
            description: 'Percentage of vendors approved for operations',
          ),
          _buildInsightItem(
            'Active Rate',
            '${_calculateActiveRate().toStringAsFixed(2)}%',
            typeColor,
            Icons.store_mall_directory,
            description: 'Percentage of vendors currently active and operational',
          ),
          _buildInsightItem(
            'Verification Rate',
            '${_calculateVerificationRate().toStringAsFixed(2)}%',
            typeColor,
            Icons.verified,
            description: 'Percentage of vendors that have completed verification',
          ),
        ];
      case 'orders':
        return [
          _buildInsightItem(
            'Total Orders',
            '${widget.analytics.orders.total}',
            typeColor,
            Icons.shopping_cart,
            description: 'Total number of orders placed in the system',
          ),
          _buildInsightItem(
            'Completed Orders',
            '${widget.analytics.orders.completed}',
            typeColor,
            Icons.check_circle,
            description: 'Number of orders successfully delivered and completed',
          ),
          _buildInsightItem(
            'Pending Orders',
            '${widget.analytics.orders.pending}',
            typeColor,
            Icons.pending,
            description: 'Orders awaiting processing or vendor assignment',
          ),
          _buildInsightItem(
            'In Progress',
            '${widget.analytics.orders.inProgress}',
            typeColor,
            Icons.local_shipping,
            description: 'Orders currently being processed or out for delivery',
          ),
          _buildInsightItem(
            "Today's Orders",
            '${widget.analytics.orders.today}',
            typeColor,
            Icons.today,
            description: 'Number of orders placed today',
          ),
          _buildInsightItem(
            'Completion Rate',
            '${_calculateCompletionRate().toStringAsFixed(2)}%',
            typeColor,
            Icons.trending_up,
            description: _getCompletionRateDescription(),
          ),
          if (_averageRating != null)
            _buildInsightItem(
              'Average Rating',
              '${_averageRating!.toStringAsFixed(2)}/5.0',
              typeColor,
              Icons.star_rounded,
              description: 'Average customer rating from $_totalRatedOrders rated orders',
            ),
          _buildInsightItem(
            'Cancellation Rate',
            '${_calculateCancellationRate().toStringAsFixed(2)}%',
            typeColor,
            Icons.cancel,
            description: _getCancellationRateDescription(),
          ),
          _buildInsightItem(
            'Average Orders/Day (This Month)',
            '${_calculateAvgOrdersPerDay().toStringAsFixed(1)}',
            typeColor,
            Icons.show_chart,
            description: 'Average number of orders per day in the current month',
          ),
          _buildInsightItem(
            'Monthly Order Projection',
            '${_calculateMonthlyOrderProjection().toStringAsFixed(0)}',
            typeColor,
            Icons.timeline,
            description: 'Projected total orders for the month based on today\'s performance',
          ),
        ];
      case 'users':
        return [
          _buildInsightItem(
            'Total Users',
            '${_filteredUsers.length}${_totalElements > 0 ? ' / $_totalElements' : ''}',
            typeColor,
            Icons.people,
          ),
          _buildInsightItem(
            'Users with Orders',
            '${_filteredUsers.where((u) => _getUserOrderCount(u) > 0).length}',
            typeColor,
            Icons.shopping_cart,
          ),
          _buildInsightItem(
            'Total Orders',
            '${_filteredUsers.fold<int>(0, (sum, u) => sum + _getUserOrderCount(u))}',
            typeColor,
            Icons.receipt,
          ),
        ];
      default:
        return [
          _buildInsightItem(
            'Total Count',
            _getTotalCount(),
            typeColor,
            Icons.numbers,
          ),
        ];
    }
  }

  Widget _buildInsightItem(String label, String value, Color color, IconData icon, {String? description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 11,
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

  Widget _buildDataList(Color typeColor) {
    switch (widget.type) {
      case 'vendors':
        return _buildVendorList();
      case 'orders':
        return _buildOrderList();
      case 'users':
        // Users use _buildScrollableUserContent directly in body
        return const SizedBox.shrink();
      default:
        return _buildGenericList();
    }
  }

  Widget _buildVendorList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendors (${_filteredStores.length})',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredStores.map((store) => _buildVendorCard(store)),
      ],
    );
  }

  // Client-side search and filter for vendors
  void _applyVendorFilters() {
    var filtered = List<Store>.from(_stores);
    
    // Apply search query first (client-side filtering)
    if (_vendorSearchQuery.trim().isNotEmpty) {
      final query = _vendorSearchQuery.toLowerCase().trim();
      filtered = filtered.where((store) {
        return store.name.toLowerCase().contains(query) ||
            store.id.toLowerCase().contains(query) ||
            (store.city?.toLowerCase().contains(query) ?? false) ||
            (store.state?.toLowerCase().contains(query) ?? false) ||
            (store.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply status filter
    if (_selectedFilter == 'active') {
      filtered = filtered.where((s) => s.isActive).toList();
    } else if (_selectedFilter == 'inactive') {
      filtered = filtered.where((s) => !s.isActive).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int compare = 0;
      switch (_vendorSortBy) {
        case 'name':
          compare = a.name.compareTo(b.name);
          break;
        case 'city':
          compare = (a.city ?? '').compareTo(b.city ?? '');
          break;
        case 'state':
          compare = (a.state ?? '').compareTo(b.state ?? '');
          break;
        default:
          compare = a.name.compareTo(b.name);
      }
      return _vendorSortAsc ? compare : -compare;
    });
    
    setState(() {
      _filteredStores = filtered;
    });
  }
  
  void _onVendorSearchChanged(String value) {
    setState(() {
      _vendorSearchQuery = value;
    });
    
    // Cancel previous timer
    _vendorSearchDebounceTimer?.cancel();
    
    // Client-side search - instant filtering on cached stores
    _vendorSearchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyVendorFilters();
    });
  }

  Widget _buildScrollableVendorContent(Color typeColor) {
    return CustomScrollView(
      controller: _vendorScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Business Insights
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _buildInsights(typeColor),
          ),
        ),
        // Search and Filter bar
        SliverToBoxAdapter(
          child: _buildVendorSearchAndFilter(typeColor),
        ),
        // Vendors header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendors (${_filteredStores.length}${_stores.length > _filteredStores.length ? ' / ${_stores.length}' : ''})',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Vendors list
        _filteredStores.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No vendors found',
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildVendorCard(_filteredStores[index]);
                    },
                    childCount: _filteredStores.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildVendorSearchAndFilter(Color typeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: _onVendorSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search vendors by name...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                prefixIcon: Icon(Icons.search, color: typeColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor.withOpacity(0.5), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Filter by status
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: GoogleFonts.inter(color: typeColor, fontWeight: FontWeight.w500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor.withOpacity(0.5), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.arrow_drop_down, color: typeColor),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('All Vendors', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'active',
                  child: Text('Active', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text('Inactive', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'all';
                  _applyVendorFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Sort
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _vendorSortBy,
              decoration: InputDecoration(
                labelText: 'Sort By',
                labelStyle: GoogleFonts.inter(color: typeColor, fontWeight: FontWeight.w500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor.withOpacity(0.5), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.arrow_drop_down, color: typeColor),
              items: [
                DropdownMenuItem(
                  value: 'name',
                  child: Text('Name', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'city',
                  child: Text('City', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'state',
                  child: Text('State', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _vendorSortBy = value ?? 'name';
                  _applyVendorFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Sort direction
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: typeColor, width: 1.5),
            ),
            child: IconButton(
              icon: Icon(
                _vendorSortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                color: typeColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _vendorSortAsc = !_vendorSortAsc;
                  _applyVendorFilters();
                });
              },
              tooltip: _vendorSortAsc ? 'Ascending' : 'Descending',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Store store) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreStatisticsScreen(store: store),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store, color: Color(0xFF8B5CF6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: store.isActive 
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              store.isActive ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: store.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                color: store.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.id,
                    style: GoogleFonts.robotoMono(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  if (store.displayLocation != 'Location N/A') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: const Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          store.displayLocation,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  /// Load orders with pagination and ratings
  Future<void> _loadOrders({bool reset = false}) async {
    if (reset) {
      setState(() {
        _orders = [];
        _orderRatings = {};
        _currentPage = 0;
      });
    }

    if (_isLoadingOrders) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      // Fetch orders from API (last 10 initially, then paginate)
      final response = await http.get(
        Uri.parse('${ApiConfig.ordersUrl}?page=${reset ? 0 : _currentPage}&size=10&sortBy=createdAt&sortAsc=false'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ordersList = data is List ? data : (data['content'] ?? data['orders'] ?? []);
        
        // Fetch ratings for delivered/completed orders that have been rated
        final newOrders = <Map<String, dynamic>>[];
        for (var order in ordersList) {
          final orderMap = order is Map<String, dynamic> ? order : Map<String, dynamic>.from(order);
          newOrders.add(orderMap);
          
          // Only fetch rating if order is delivered/completed AND has orderRatingId (has been rated)
          final status = orderMap['status']?.toString().toUpperCase() ?? '';
          final orderRatingId = orderMap['orderRatingId'] ?? orderMap['order_rating_id'];
          if ((status == 'DELIVERED' || status == 'ORDER_COMPLETED') && orderRatingId != null) {
            await _fetchOrderRating(orderMap['id']?.toString() ?? '');
          }
        }

        // Update total elements if available
        int? totalElements;
        if (data is Map<String, dynamic>) {
          totalElements = data['totalElements'] as int?;
        }

        setState(() {
          if (reset) {
            _orders = newOrders;
            _currentPage = 0;
          } else {
            _orders.addAll(newOrders);
            _currentPage = _currentPage + 1;
          }
          if (totalElements != null) {
            _totalElements = totalElements;
          }
          _isLoadingOrders = false;
        });

        // Calculate average rating after a short delay to allow ratings to load
        Future.delayed(const Duration(milliseconds: 500), () {
          _calculateAverageRating();
        });
      } else {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  /// Load more orders (pagination)
  Future<void> _loadMoreOrders() async {
    if (_isLoadingMoreOrders || _isLoadingOrders) return;
    
    setState(() {
      _isLoadingMoreOrders = true;
    });

    await _loadOrders();
    
    setState(() {
      _isLoadingMoreOrders = false;
    });
  }

  /// Fetch rating for a specific order
  Future<void> _fetchOrderRating(String orderId) async {
    if (orderId.isEmpty || _orderRatings.containsKey(orderId)) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getOrderRatingUrl(orderId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final ratingData = json.decode(response.body);
        setState(() {
          _orderRatings[orderId] = ratingData is Map<String, dynamic> 
              ? ratingData 
              : Map<String, dynamic>.from(ratingData);
        });
      }
    } catch (e) {
      // 404 is expected for unrated orders - silently ignore
      print('Rating fetch for order $orderId: ${e.toString()}');
    }
  }

  /// Calculate average rating from all rated orders
  void _calculateAverageRating() {
    final ratings = _orderRatings.values
        .where((r) => r['rating'] != null)
        .map((r) => (r['rating'] as num).toDouble())
        .toList();

    if (ratings.isEmpty) {
      setState(() {
        _averageRating = null;
        _totalRatedOrders = 0;
      });
      return;
    }

    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    setState(() {
      _averageRating = average;
      _totalRatedOrders = ratings.length;
    });
  }

  Widget _buildOrderList() {
    final typeColor = _getTypeColor();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average Rating Card
        if (_averageRating != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Rating',
                        style: GoogleFonts.inter(
                          color: Colors.amber.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_averageRating!.toStringAsFixed(2)}/5.0',
                        style: GoogleFonts.inter(
                          color: Colors.amber.shade900,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Based on $_totalRatedOrders rated orders',
                        style: GoogleFonts.inter(
                          color: Colors.amber.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Orders Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders (${_orders.length}${_totalElements > 0 ? ' / $_totalElements' : ''})',
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoadingOrders)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Orders List
        if (_orders.isEmpty && !_isLoadingOrders)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No orders found',
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _orderScrollController,
              itemCount: _orders.length + (_isLoadingMoreOrders ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _orders.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final order = _orders[index];
                final orderId = order['id']?.toString() ?? '';
                final rating = _orderRatings[orderId];
                
                return _buildOrderCard(order, rating, typeColor);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, Map<String, dynamic>? rating, Color typeColor) {
    final orderId = order['id']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'UNKNOWN';
    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final totalItems = (order['totalItems'] as int?) ?? 0;
    final createdAt = order['createdAt']?.toString() ?? '';
    final rejectionReason = order['rejectionReason']?.toString();
    final customerName = order['customerName']?.toString() ?? 'Customer';
    
    // Parse date
    DateTime? orderDate;
    try {
      orderDate = createdAt.isNotEmpty ? DateTime.parse(createdAt) : null;
    } catch (e) {
      orderDate = null;
    }
    
    // Get status color
    Color statusColor = _getOrderStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatOrderStatus(status),
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (orderDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(orderDate),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Rating Badge
              if (rating != null && rating['rating'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        (rating['rating'] as num).toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: Colors.amber.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Order Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: $customerName',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Items: $totalItems | Amount: ₹${totalAmount.toStringAsFixed(2)}',
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
          
          // Rejection Reason (if rejected)
          if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection: $rejectionReason',
                      style: GoogleFonts.inter(
                        color: Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Rating Details (if rated)
          if (rating != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Overall: ${(rating['rating'] as num).toStringAsFixed(1)}/5.0',
                        style: GoogleFonts.inter(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (rating['deliveryRating'] != null || rating['productRating'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (rating['deliveryRating'] != null) ...[
                          Expanded(
                            child: Text(
                              'Delivery: ${(rating['deliveryRating'] as num).toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                color: Colors.amber.shade800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                        if (rating['productRating'] != null) ...[
                          Expanded(
                            child: Text(
                              'Product: ${(rating['productRating'] as num).toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                color: Colors.amber.shade800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (rating['comment'] != null && (rating['comment'] as String).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"${rating['comment']}"',
                      style: GoogleFonts.inter(
                        color: Colors.amber.shade900,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    final upperStatus = status.toUpperCase();
    switch (upperStatus) {
      case 'ORDER_COMPLETED':
      case 'DELIVERED':
        return const Color(0xFF10B981); // Green
      case 'ORDER_PLACED':
      case 'PENDING_FULFILLMENT':
        return const Color(0xFF3B82F6); // Blue
      case 'OUT_FOR_DELIVERY':
      case 'ORDER_CONFIRMED':
        return const Color(0xFF8B5CF6); // Purple
      case 'ORDER_CANCELLED':
      case 'PRESCRIPTION_REJECTED':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _formatOrderStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildSearchAndFilter(Color typeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                prefixIcon: Icon(Icons.search, color: typeColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor.withOpacity(0.5), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Filter by status
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: GoogleFonts.inter(color: typeColor, fontWeight: FontWeight.w500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor.withOpacity(0.5), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.arrow_drop_down, color: typeColor),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('All Users', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'active',
                  child: Text('Has Orders', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text('No Orders', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'all';
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Sort
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                labelText: 'Sort By',
                labelStyle: GoogleFonts.inter(color: typeColor, fontWeight: FontWeight.w500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor.withOpacity(0.5), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: typeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.arrow_drop_down, color: typeColor),
              items: [
                DropdownMenuItem(
                  value: 'createdAt',
                  child: Text('Created Date', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'fullName',
                  child: Text('Name', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'totalOrders',
                  child: Text('Orders', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
                DropdownMenuItem(
                  value: 'email',
                  child: Text('Email', style: GoogleFonts.inter(color: const Color(0xFF1F2937))),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value ?? 'createdAt';
                  _loadUsers(reset: true); // Sort requires server reload
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Sort direction
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: typeColor, width: 1.5),
            ),
            child: IconButton(
              icon: Icon(
                _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                color: typeColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _sortAsc = !_sortAsc;
                  _loadUsers(reset: true); // Sort requires server reload
                });
              },
              tooltip: _sortAsc ? 'Ascending' : 'Descending',
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    // Client-side search - instant filtering on cached users
    // Only reload from server if we don't have enough cached data
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyClientSideSearch();
      
      // If search query is empty or we have enough cached users, just filter
      // Otherwise, if search is too specific and we don't have results, reload from server
      if (_searchQuery.trim().isNotEmpty && _filteredUsers.isEmpty && _users.length < _totalElements) {
        // Reload from server with search query if we don't have enough cached data
        _loadUsers();
      }
    });
  }

  void _applyFilters() {
    // Filters require server-side reload, so reset and reload
    _loadUsers(reset: true);
  }

  Future<void> _loadUsers({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoadingUsers = true;
        _users = [];
        _filteredUsers = [];
        _currentPage = 0;
      });
    }

    try {
      // Only send search to server if we're resetting or if search is very specific
      // Otherwise, use client-side search on cached data
      final data = await ApiService.getAllUsers(
        page: 0,
        size: _pageSize,
        sortBy: _sortBy,
        sortAsc: _sortAsc,
        // Only search on server if we're doing initial load or filter/sort changed
        // For typing in search, use client-side filtering
        search: reset && _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );
      
      setState(() {
        if (reset) {
          _users = data['users'] as List<User>;
        } else {
          // Append to existing users for pagination
          _users.addAll(data['users'] as List<User>);
        }
        _totalElements = data['totalElements'] as int;
        _totalPages = data['totalPages'] as int;
        _currentPage = 0;
        _loadUserOrderCounts();
        _applyClientSideSearch(); // Apply search and filter on loaded data
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (!_hasMoreItems || _isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      final data = await ApiService.getAllUsers(
        page: nextPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortAsc: _sortAsc,
        // Don't send search query for pagination - we'll filter client-side
        search: null,
      );
      
      setState(() {
        final newUsers = data['users'] as List<User>;
        _users.addAll(newUsers);
        _currentPage = nextPage;
        _totalElements = data['totalElements'] as int;
        _totalPages = data['totalPages'] as int;
        _loadUserOrderCounts();
        _applyClientSideSearch(); // Re-apply search and filter on expanded dataset
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadUserOrderCounts() async {
    try {
      // Get unique user emails from loaded users
      final userEmails = _users.map((u) => u.email).where((e) => e.isNotEmpty).toSet().toList();
      
      if (userEmails.isEmpty) {
        print('No user emails to fetch order counts for');
        return;
      }
      
      // Create map of user ID -> email for matching
      final userIdToEmail = <String, String>{};
      for (final user in _users) {
        if (user.email.isNotEmpty) {
          userIdToEmail['${user.id}'] = user.email;
          userIdToEmail[user.email] = user.email;
        }
      }
      
      print('Loading order counts for ${userEmails.length} users');
      print('User emails: $userEmails');
      print('User ID map: $userIdToEmail');
      
      // Fetch order counts for all users
      final counts = await ApiService.getUserOrderCounts(userEmails, userIdToEmailMap: userIdToEmail);
      
      print('Received order counts: $counts');
      
      setState(() {
        _userOrderCounts = counts;
        // Also update filtered users to reflect new counts
        _applyClientSideFilter();
      });
    } catch (e) {
      print('Error loading user order counts: $e');
    }
  }

  int _getUserOrderCount(User user) {
    // Use actual order count from API if available, otherwise fall back to cached value
    return _userOrderCounts[user.email] ?? user.totalOrders;
  }

  // Client-side search on already loaded users (instant, no server call)
  void _applyClientSideSearch() {
    var filtered = List<User>.from(_users);
    
    // Apply search query first (client-side filtering)
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phoneNumber?.toLowerCase().contains(query) ?? false) ||
            (user.city?.toLowerCase().contains(query) ?? false) ||
            (user.state?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply status filter - Active means has placed orders
    if (_selectedFilter == 'active') {
      filtered = filtered.where((u) => _getUserOrderCount(u) > 0).toList();
    } else if (_selectedFilter == 'inactive') {
      filtered = filtered.where((u) => _getUserOrderCount(u) == 0).toList();
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _applyClientSideFilter() {
    // This method now just calls the combined search + filter method
    _applyClientSideSearch();
  }

  Widget _buildScrollableUserContent(Color typeColor) {
    if (_isLoadingUsers && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Business Insights
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _buildInsights(typeColor),
          ),
        ),
        // Search and Filter bar
        SliverToBoxAdapter(
          child: _buildSearchAndFilter(typeColor),
        ),
        // Users header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Users (${_filteredUsers.length}${_totalElements > _filteredUsers.length ? ' / $_totalElements' : ''})',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_totalElements > 0)
                  Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Users list
        _filteredUsers.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _isLoadingUsers ? 'Loading users...' : 'No users found',
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _filteredUsers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildUserCard(_filteredUsers[index]);
                    },
                    childCount: _filteredUsers.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
      ],
    );
  }


  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (user.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                      ),
                    if (user.isActive)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF3B82F6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      user.phoneNumber,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.shopping_cart, size: 14, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      '${_getUserOrderCount(user)} orders',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (user.city != null || user.state != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${user.city ?? ''}${user.city != null && user.state != null ? ', ' : ''}${user.state ?? ''}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: const Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _buildGenericList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Detailed data view coming soon',
          style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }

  // Insight calculation methods
  String _calculateRevenueGrowth() {
    final thisMonth = widget.analytics.revenue.thisMonth;
    final today = widget.analytics.revenue.today;
    if (thisMonth == 0) return '0.00%';
    final dailyAvg = thisMonth / DateTime.now().day; // Use actual days in month so far
    if (dailyAvg == 0) return '0.00%';
    final growth = ((today - dailyAvg) / dailyAvg * 100);
    return '${growth.toStringAsFixed(2)}%';
  }
  
  String _getRevenueGrowthDescription() {
    final thisMonth = widget.analytics.revenue.thisMonth;
    final today = widget.analytics.revenue.today;
    if (thisMonth == 0 || today == 0) {
      return 'No revenue data available for comparison';
    }
    final dailyAvg = thisMonth / DateTime.now().day;
    if (dailyAvg == 0) {
      return 'Insufficient data to calculate growth';
    }
    final growth = ((today - dailyAvg) / dailyAvg * 100);
    if (growth > 0) {
      return 'Today\'s revenue is ${growth.toStringAsFixed(2)}% above the month\'s daily average - positive trend';
    } else if (growth < 0) {
      return 'Today\'s revenue is ${(-growth).toStringAsFixed(2)}% below the month\'s daily average - needs attention';
    } else {
      return 'Today\'s revenue matches the month\'s daily average';
    }
  }
  
  double _calculateDailyAverage() {
    final thisMonth = widget.analytics.revenue.thisMonth;
    final daysInMonth = DateTime.now().day;
    if (daysInMonth == 0) return 0;
    return thisMonth / daysInMonth;
  }

  double _calculateAOV() {
    final totalRevenue = widget.analytics.revenue.total;
    final totalOrders = widget.analytics.orders.completed;
    if (totalOrders == 0) return 0;
    return totalRevenue / totalOrders;
  }

  double _calculateMonthlyProjection() {
    final today = widget.analytics.revenue.today;
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    return today * daysInMonth; // Project based on actual days in month
  }

  double _calculateApprovalRate() {
    final total = widget.analytics.vendors.total;
    if (total == 0) return 0;
    return (widget.analytics.vendors.approved / total * 100);
  }

  double _calculateActiveRate() {
    final total = widget.analytics.vendors.total;
    if (total == 0) return 0;
    return (widget.analytics.vendors.open / total * 100);
  }

  double _calculateVerificationRate() {
    final total = widget.analytics.vendors.total;
    if (total == 0) return 0;
    return (widget.analytics.vendors.verified / total * 100);
  }

  double _calculateCompletionRate() {
    final total = widget.analytics.orders.total;
    if (total == 0) return 0;
    return (widget.analytics.orders.completed / total * 100);
  }

  double _calculateCancellationRate() {
    final total = widget.analytics.orders.total;
    if (total == 0) return 0;
    return (widget.analytics.orders.cancelled / total * 100);
  }

  double _calculateAvgOrdersPerDay() {
    final thisMonthOrders = _getThisMonthOrdersCount();
    final daysInMonth = DateTime.now().day;
    if (daysInMonth == 0) return 0;
    return thisMonthOrders / daysInMonth;
  }
  
  int _getThisMonthOrdersCount() {
    // This is an approximation - ideally we'd have thisMonthOrders in OrderStats
    // For now, we'll estimate based on total orders and today's orders
    // A better implementation would track this in the analytics service
    final total = widget.analytics.orders.total;
    final today = widget.analytics.orders.today;
    // Rough estimate: assume orders are distributed somewhat evenly
    // This is a placeholder - should be improved with actual monthly tracking
    return (total * DateTime.now().day / 30).round();
  }
  
  double _calculateMonthlyOrderProjection() {
    final today = widget.analytics.orders.today;
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    return (today * daysInMonth).toDouble();
  }
  
  String _getCompletionRateDescription() {
    final rate = _calculateCompletionRate();
    if (rate >= 90) {
      return 'Excellent completion rate (${rate.toStringAsFixed(2)}%) - Strong operational performance';
    } else if (rate >= 75) {
      return 'Good completion rate (${rate.toStringAsFixed(2)}%) - Above average performance';
    } else if (rate >= 50) {
      return 'Moderate completion rate (${rate.toStringAsFixed(2)}%) - Room for improvement';
    } else {
      return 'Low completion rate (${rate.toStringAsFixed(2)}%) - Needs immediate attention';
    }
  }
  
  String _getCancellationRateDescription() {
    final rate = _calculateCancellationRate();
    if (rate <= 5) {
      return 'Low cancellation rate (${rate.toStringAsFixed(2)}%) - Excellent customer satisfaction';
    } else if (rate <= 10) {
      return 'Moderate cancellation rate (${rate.toStringAsFixed(2)}%) - Within acceptable range';
    } else if (rate <= 20) {
      return 'High cancellation rate (${rate.toStringAsFixed(2)}%) - Review order fulfillment process';
    } else {
      return 'Very high cancellation rate (${rate.toStringAsFixed(2)}%) - Critical issue requiring action';
    }
  }

  String _getTotalCount() {
    switch (widget.type) {
      case 'medicines':
        return '${widget.analytics.medicines.total}';
      case 'documents':
        return '${widget.analytics.documents.total}';
      case 'managers':
        return '${widget.analytics.managers.total}';
      default:
        return '0';
    }
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

