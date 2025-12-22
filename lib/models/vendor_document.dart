class VendorDocument {
  final int id;
  final String vendorId;
  final String documentType;
  final String? documentUrl;
  final String? gcsObjectKey;
  final String documentStatus;
  final String? documentNumber;
  final String? documentName;
  final String? additionalInfo;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final String? reviewerComments;

  VendorDocument({
    required this.id,
    required this.vendorId,
    required this.documentType,
    this.documentUrl,
    this.gcsObjectKey,
    required this.documentStatus,
    this.documentNumber,
    this.documentName,
    this.additionalInfo,
    required this.uploadedAt,
    this.reviewedAt,
    this.reviewerComments,
  });

  factory VendorDocument.fromJson(Map<String, dynamic> json) {
    return VendorDocument(
      id: json['id'] ?? 0,
      vendorId: json['vendorId'] ?? '',
      documentType: json['documentType'] ?? '',
      documentUrl: json['documentUrl'],
      gcsObjectKey: json['gcsObjectKey'],
      documentStatus: json['documentStatus'] ?? 'UPLOADED',
      documentNumber: json['documentNumber'],
      documentName: json['documentName'],
      additionalInfo: json['additionalInfo'],
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt']) 
          : DateTime.now(),
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.parse(json['reviewedAt']) 
          : null,
      reviewerComments: json['reviewerComments'],
    );
  }

  bool get hasDocument => gcsObjectKey != null || documentUrl != null;

  bool get isPending => documentStatus == 'UPLOADED';
  bool get isApproved => documentStatus == 'APPROVED';
  bool get isRejected => documentStatus == 'REJECTED';

  String get displayType {
    switch (documentType) {
      case 'PAN_CARD':
        return 'PAN Card';
      case 'DRUG_LICENSE_20B':
        return 'Drug License (20B)';
      case 'DRUG_LICENSE_21B':
        return 'Drug License (21B)';
      case 'GST_CERTIFICATE':
        return 'GST Certificate';
      case 'IDENTITY_PROOF':
        return 'Identity Proof';
      default:
        return documentType;
    }
  }
}

class VendorActivationStatus {
  final String vendorId;
  final String activationStatus;
  final bool isVerified;
  final List<VendorDocument> documents;
  final int uploadedDocuments;
  final int approvedDocuments;
  final int totalRequiredDocuments;
  final bool basicInfoCompleted;
  final bool panCardCompleted;
  final bool drugLicenseCompleted;

  VendorActivationStatus({
    required this.vendorId,
    required this.activationStatus,
    required this.isVerified,
    required this.documents,
    required this.uploadedDocuments,
    required this.approvedDocuments,
    required this.totalRequiredDocuments,
    required this.basicInfoCompleted,
    required this.panCardCompleted,
    required this.drugLicenseCompleted,
  });

  factory VendorActivationStatus.fromJson(Map<String, dynamic> json) {
    final docs = (json['documents'] as List<dynamic>?)
        ?.map((d) => VendorDocument.fromJson(d))
        .toList() ?? [];
    
    return VendorActivationStatus(
      vendorId: json['vendorId'] ?? '',
      activationStatus: json['activationStatus'] ?? 'PENDING',
      isVerified: json['isVerified'] ?? false,
      documents: docs,
      uploadedDocuments: json['uploadedDocuments'] ?? 0,
      approvedDocuments: json['approvedDocuments'] ?? 0,
      totalRequiredDocuments: json['totalRequiredDocuments'] ?? 2,
      basicInfoCompleted: json['basicInfoCompleted'] ?? false,
      panCardCompleted: json['panCardCompleted'] ?? false,
      drugLicenseCompleted: json['drugLicenseCompleted'] ?? false,
    );
  }

  bool get canApprove => approvedDocuments >= totalRequiredDocuments;
  
  List<VendorDocument> get pendingDocuments => 
      documents.where((d) => d.isPending).toList();
}

