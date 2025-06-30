import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String reportId;
  final String? userId; 
  final String title;
  final String description;
  final String status;
  final Timestamp incidentDate;
  final Timestamp reportDate;
  final String address;
  final GeoPoint? location;
  final int evidenceCount;
  final List<String> evidenceUrls;
  final bool isAnonymous;
  final String contactPreference;
  final String assignedTo;

  Report({
    required this.reportId,
    this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.incidentDate,
    required this.reportDate,
    required this.address,
    this.location,
    required this.evidenceCount,
    required this.evidenceUrls,
    required this.isAnonymous,
    required this.contactPreference,
    required this.assignedTo,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Report(
      reportId: doc.id,
      userId: data['userId'],
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      status: data['status'] ?? 'new',
      incidentDate: data['incidentDate'] ?? Timestamp.now(),
      reportDate: data['reportDate'] ?? Timestamp.now(),
      address: data['address'] ?? 'No Address',
      location: data['location'],
      evidenceCount: data['evidenceCount'] ?? 0,
      evidenceUrls: List<String>.from(data['evidenceUrls'] ?? []),
      isAnonymous: data['isAnonymous'] ?? false,
      contactPreference: data['contactPreference'] ?? 'N/A',
      assignedTo: data['assignedTo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'status': status,
      'incidentDate': incidentDate,
      'reportDate': reportDate,
      'address': address,
      'location': location,
      'evidenceCount': evidenceCount,
      'evidenceUrls': evidenceUrls,
      'isAnonymous': isAnonymous,
      'contactPreference': contactPreference,
      'assignedTo': assignedTo,
    };
  }

  Report copyWith({String? status}) {
    return Report(
      reportId: reportId,
      userId: userId,
      title: title,
      description: description,
      status: status ?? this.status,
      incidentDate: incidentDate,
      reportDate: reportDate,
      address: address,
      location: location,
      evidenceCount: evidenceCount,
      evidenceUrls: evidenceUrls,
      isAnonymous: isAnonymous,
      contactPreference: contactPreference,
      assignedTo: assignedTo,
    );
  }
}