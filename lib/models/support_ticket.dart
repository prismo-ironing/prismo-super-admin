/// Model for Support Ticket (Super Admin)
class SupportTicket {
  final String id;
  final String customerId;
  final String? orderId;
  final String issueCategory;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assignedTo;
  final String? agentResponse;
  final String? attachmentFileUrl;
  final String? attachmentGcsObjectKey;
  final String? attachmentFileName;
  final String? attachmentFileType;
  final int? attachmentFileSize;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  SupportTicket({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.issueCategory,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.agentResponse,
    this.attachmentFileUrl,
    this.attachmentGcsObjectKey,
    this.attachmentFileName,
    this.attachmentFileType,
    this.attachmentFileSize,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      orderId: json['orderId'] as String?,
      issueCategory: json['issueCategory'] as String? ?? 'OTHER',
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'MEDIUM',
      assignedTo: json['assignedTo'] as String?,
      agentResponse: json['agentResponse'] as String?,
      attachmentFileUrl: json['attachmentFileUrl'] as String?,
      attachmentGcsObjectKey: json['attachmentGcsObjectKey'] as String?,
      attachmentFileName: json['attachmentFileName'] as String?,
      attachmentFileType: json['attachmentFileType'] as String?,
      attachmentFileSize: json['attachmentFileSize'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.tryParse(json['resolvedAt']) 
          : null,
    );
  }

  bool get isOpen => status == 'OPEN';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED';
  bool get isClosed => status == 'CLOSED';
  bool get hasAttachment => attachmentFileUrl != null && attachmentFileUrl!.isNotEmpty;
}

/// Response model for paginated tickets
class TicketsResponse {
  final List<SupportTicket> tickets;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int size;

  TicketsResponse({
    required this.tickets,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.size,
  });

  factory TicketsResponse.fromJson(Map<String, dynamic> json) {
    final ticketsList = (json['tickets'] as List<dynamic>?)
        ?.map((t) => SupportTicket.fromJson(t as Map<String, dynamic>))
        .toList() ?? [];
    
    return TicketsResponse(
      tickets: ticketsList,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
    );
  }
}

/// Ticket statistics model
class TicketStatistics {
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final int closedTickets;

  TicketStatistics({
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.closedTickets,
  });

  factory TicketStatistics.fromJson(Map<String, dynamic> json) {
    return TicketStatistics(
      totalTickets: json['totalTickets'] as int? ?? 0,
      openTickets: json['openTickets'] as int? ?? 0,
      inProgressTickets: json['inProgressTickets'] as int? ?? 0,
      resolvedTickets: json['resolvedTickets'] as int? ?? 0,
      closedTickets: json['closedTickets'] as int? ?? 0,
    );
  }
}

