import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../models/store.dart';
import '../models/manager.dart';
import '../models/user.dart';

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
  
  // Order counts map (userId -> orderCount)
  Map<String, int> _userOrderCounts = {};
  
  // Pagination
  static const int _pageSize = 50;
  int _currentPage = 0;
  int _totalElements = 0;
  int _totalPages = 0;
  bool get _hasMoreItems => _currentPage < _totalPages - 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.type == 'users') {
      _scrollController.addListener(_onScroll);
      _loadUsers();
    }
  }
  
  @override
  void dispose() {
    if (widget.type == 'users') {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreItems && !_isLoadingUsers && !_isLoadingMore) {
        _loadMoreUsers();
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
              ? Column(
                  children: [
                    // Business Insights at the top
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildInsights(typeColor),
                    ),
                    // Search and Filter bar
                    _buildSearchAndFilter(typeColor),
                    // Users list (scrollable)
                    Expanded(child: _buildUserList()),
                  ],
                )
              : Column(
                  children: [
                    if (widget.type != 'users') _buildFilters(typeColor),
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
          {'value': 'approved', 'label': 'Approved'},
          {'value': 'pending', 'label': 'Pending'},
          {'value': 'rejected', 'label': 'Rejected'},
          {'value': 'verified', 'label': 'Verified'},
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
            'Revenue Growth',
            _calculateRevenueGrowth(),
            typeColor,
            Icons.trending_up,
          ),
          _buildInsightItem(
            'Average Order Value',
            _formatCurrency(_calculateAOV()),
            typeColor,
            Icons.receipt,
          ),
          _buildInsightItem(
            'Monthly Projection',
            _formatCurrency(_calculateMonthlyProjection()),
            typeColor,
            Icons.calendar_month,
          ),
        ];
      case 'vendors':
        return [
          _buildInsightItem(
            'Approval Rate',
            '${_calculateApprovalRate()}%',
            typeColor,
            Icons.check_circle,
          ),
          _buildInsightItem(
            'Active Rate',
            '${_calculateActiveRate()}%',
            typeColor,
            Icons.store_mall_directory,
          ),
          _buildInsightItem(
            'Verification Rate',
            '${_calculateVerificationRate()}%',
            typeColor,
            Icons.verified,
          ),
        ];
      case 'orders':
        return [
          _buildInsightItem(
            'Completion Rate',
            '${_calculateCompletionRate()}%',
            typeColor,
            Icons.check_circle,
          ),
          _buildInsightItem(
            'Cancellation Rate',
            '${_calculateCancellationRate()}%',
            typeColor,
            Icons.cancel,
          ),
          _buildInsightItem(
            'Average Orders/Day',
            '${_calculateAvgOrdersPerDay()}',
            typeColor,
            Icons.today,
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

  Widget _buildInsightItem(String label, String value, Color color, IconData icon) {
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
        return _buildUserList();
      default:
        return _buildGenericList();
    }
  }

  Widget _buildVendorList() {
    final filteredStores = _getFilteredStores();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendors (${filteredStores.length})',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...filteredStores.map((store) => _buildVendorCard(store)),
      ],
    );
  }

  List<Store> _getFilteredStores() {
    var stores = _stores;
    
    if (_selectedFilter == 'approved') {
      // Filter by activation status - would need to check each store
      return stores;
    }
    
    return stores;
  }

  Widget _buildVendorCard(Store store) {
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
                Text(
                  store.name,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.id,
                  style: GoogleFonts.robotoMono(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
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

  Widget _buildOrderList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orders',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Order details will be loaded from API',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
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
                  _loadUsers();
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
                  _loadUsers();
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
    
    // Debounce search - reload after user stops typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) {
        _loadUsers();
      }
    });
  }

  void _applyFilters() {
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _users = [];
      _filteredUsers = [];
      _currentPage = 0;
    });

    try {
      final data = await ApiService.getAllUsers(
        page: 0,
        size: _pageSize,
        sortBy: _sortBy,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      
      setState(() {
        _users = data['users'] as List<User>;
        _totalElements = data['totalElements'] as int;
        _totalPages = data['totalPages'] as int;
        _loadUserOrderCounts();
        _applyClientSideFilter();
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
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      
      setState(() {
        final newUsers = data['users'] as List<User>;
        _users.addAll(newUsers);
        _currentPage = nextPage;
        _totalElements = data['totalElements'] as int;
        _totalPages = data['totalPages'] as int;
        _loadUserOrderCounts();
        _applyClientSideFilter();
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

  void _applyClientSideFilter() {
    var filtered = List<User>.from(_users);
    
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

  Widget _buildUserList() {
    if (_isLoadingUsers && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 16),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      _isLoadingUsers ? 'Loading users...' : 'No users found',
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredUsers.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
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
                  ),
          ),
        ],
      ),
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
    if (thisMonth == 0) return '0%';
    final dailyAvg = thisMonth / 30;
    if (dailyAvg == 0) return '0%';
    final growth = ((today - dailyAvg) / dailyAvg * 100);
    return '${growth.toStringAsFixed(1)}%';
  }

  double _calculateAOV() {
    final totalRevenue = widget.analytics.revenue.total;
    final totalOrders = widget.analytics.orders.completed;
    if (totalOrders == 0) return 0;
    return totalRevenue / totalOrders;
  }

  double _calculateMonthlyProjection() {
    final today = widget.analytics.revenue.today;
    return today * 30; // Simple projection
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
    final today = widget.analytics.orders.today;
    return today.toDouble();
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

