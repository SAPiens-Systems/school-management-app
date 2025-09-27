import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projects/home/views/announcment_edit_screen';
import 'package:provider/provider.dart';

// Models
enum AnnouncementPriority { normal, urgent }

enum AnnouncementStatus { active, scheduled, archived }

extension AnnouncementPriorityExt on AnnouncementPriority {
  String get key {
    switch (this) {
      case AnnouncementPriority.normal:
        return 'normal';
      case AnnouncementPriority.urgent:
        return 'urgent';
    }
  }

  static AnnouncementPriority fromKey(String key) {
    switch (key) {
      case 'urgent':
        return AnnouncementPriority.urgent;
      default:
        return AnnouncementPriority.normal;
    }
  }
}

extension AnnouncementStatusExt on AnnouncementStatus {
  String get key {
    switch (this) {
      case AnnouncementStatus.active:
        return 'active';
      case AnnouncementStatus.scheduled:
        return 'scheduled';
      case AnnouncementStatus.archived:
        return 'archived';
    }
  }

  static AnnouncementStatus fromKey(String key) {
    switch (key) {
      case 'scheduled':
        return AnnouncementStatus.scheduled;
      case 'archived':
        return AnnouncementStatus.archived;
      default:
        return AnnouncementStatus.active;
    }
  }
}

class AnnouncementAttachment {
  final String url;
  final String name;
  final String type;
  final int size;

  AnnouncementAttachment({
    required this.url,
    required this.name,
    required this.type,
    required this.size,
  });

  Map<String, dynamic> toMap() {
    return {'url': url, 'name': name, 'type': type, 'size': size};
  }

  factory AnnouncementAttachment.fromMap(Map<String, dynamic> map) {
    return AnnouncementAttachment(
      url: map['url'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'other',
      size: map['size'] ?? 0,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final List<AnnouncementAttachment> attachments;
  final String createdBy;
  final Map<String, dynamic> targetAudience;
  final AnnouncementPriority priority;
  final AnnouncementStatus status;
  final bool isPinned;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> readReceipts;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.attachments,
    required this.createdBy,
    required this.targetAudience,
    required this.priority,
    required this.status,
    required this.isPinned,
    this.scheduledAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.readReceipts,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'createdBy': createdBy,
      'targetAudience': targetAudience,
      'priority': priority.key,
      'status': status.key,
      'isPinned': isPinned,
      'scheduledAt': scheduledAt,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'readReceipts': readReceipts,
    };
  }

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((a) => AnnouncementAttachment.fromMap(a))
          .toList(),
      createdBy: data['createdBy'] ?? '',
      targetAudience: Map<String, dynamic>.from(data['targetAudience'] ?? {}),
      priority: AnnouncementPriorityExt.fromKey(data['priority'] ?? 'normal'),
      status: AnnouncementStatusExt.fromKey(data['status'] ?? 'active'),
      isPinned: data['isPinned'] ?? false,
      scheduledAt: data['scheduledAt']?.toDate(),
      expiresAt: data['expiresAt']?.toDate(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      readReceipts: Map<String, dynamic>.from(data['readReceipts'] ?? {}),
    );
  }
}

// Repository
class AnnouncementsRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  String schoolId;

  AnnouncementsRepository({
    required this.schoolId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance;

  Stream<List<Announcement>> getAnnouncements({
    required String userId,
    required String userRole,
    String? userClass,
    AnnouncementStatus status = AnnouncementStatus.active,
  }) {
    // Build query based on user role and filters
    Query query = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .where('status', isEqualTo: status.key)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true);

    // For non-admins, filter by target audience
    if (userRole != 'admin') {
      query = query.where('targetAudience.roles', arrayContains: userRole);

      if (userClass != null) {
        query = query.where('targetAudience.classes', arrayContains: userClass);
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
    });
  }

  Future<String> createAnnouncement(Announcement announcement) async {
    final docRef = firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .doc();

    await docRef.set(announcement.toMap());
    return docRef.id;
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .doc(announcement.id)
        .update(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  Future<void> markAsRead(String announcementId, String userId) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .doc(announcementId)
        .update({
          'readReceipts.$userId': {
            'read': true,
            'acknowledged': false,
            'timestamp': FieldValue.serverTimestamp(),
          },
        });
  }

  Future<void> acknowledgeAnnouncement(
    String announcementId,
    String userId,
  ) async {
    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .doc(announcementId)
        .update({
          'readReceipts.$userId.acknowledged': true,
          'readReceipts.$userId.timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<String> uploadAttachment(XFile file) async {
    try {
      // Request permissions if needed
      if (!kIsWeb) {
        await Permission.photos.request();
        await Permission.storage.request();
      }

      // Create a reference to the location you want to upload to in Firebase Storage
      final ref = storage
          .ref()
          .child('schools/$schoolId/announcements')
          .child('${DateTime.now().millisecondsSinceEpoch}_${file.name}');

      // Upload the file
      final uploadTask = ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: file.mimeType),
      );

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}

// Providers
class AnnouncementsProvider with ChangeNotifier {
  final AnnouncementsRepository repository;
  final String userId;
  final String userRole;
  final String? userClass;

  List<Announcement> _announcements = [];
  AnnouncementStatus _currentFilterStatus = AnnouncementStatus.active;
  bool _isLoading = false;
  String _searchQuery = '';

  List<Announcement> get announcements {
    var filtered = _announcements;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (announcement) =>
                announcement.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                announcement.body.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  bool get isLoading => _isLoading;
  AnnouncementStatus get currentFilterStatus => _currentFilterStatus;
  String get searchQuery => _searchQuery;

  AnnouncementsProvider({
    required this.repository,
    required this.userId,
    required this.userRole,
    this.userClass,
  });

  Future<void> loadAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stream = repository.getAnnouncements(
        userId: userId,
        userRole: userRole,
        userClass: userClass,
        status: _currentFilterStatus,
      );

      stream.listen(
        (announcements) {
          _announcements = announcements;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterStatus(AnnouncementStatus status) {
    _currentFilterStatus = status;
    loadAnnouncements();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> markAsRead(String announcementId) async {
    await repository.markAsRead(announcementId, userId);
  }

  Future<void> acknowledgeAnnouncement(String announcementId) async {
    await repository.acknowledgeAnnouncement(announcementId, userId);
  }
}

// Widgets
class AnnouncementsScreen extends StatefulWidget {
  final String schoolId;

  const AnnouncementsScreen({Key? key, required this.schoolId})
    : super(key: key);

  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  String? _userRole;
  String? _userClass;
  late AnnouncementsProvider _provider;
  List<String> _availableClasses = [];
  String _selectedClass = 'All Classes';
  bool _isLoadingClasses = false;
  Map<String, String> _classMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;

      // Get user role and class from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _userRole = data['role'] ?? 'student';
        _userClass = data['classId'];

        setState(() {
          _provider = AnnouncementsProvider(
            repository: AnnouncementsRepository(schoolId: widget.schoolId),
            userId: _userId!,
            userRole: _userRole!,
            userClass: _userClass,
          );
        });

        _provider.loadAnnouncements();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null || _userRole == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<AnnouncementsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Announcements'),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: AnnouncementsSearchDelegate(provider),
                    );
                  },
                ),
                if (_userRole == 'admin')
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAnnouncementScreen(
                            schoolId: widget.schoolId,
                            userId: _userId!,
                            userRole: _userRole!,
                          ),
                        ),
                      );
                      if (result == true) {
                        provider.loadAnnouncements();
                      }
                      // IconButton(
                      //   icon: Icon(Icons.add),
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => CreateAnnouncementScreen(
                      //           schoolId: widget.schoolId,
                      //           userId: _userId!,
                      //           userRole: _userRole!,
                      //         ),
                      //       ),
                      //     );
                    },
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                onTap: (index) {
                  final status = index == 0
                      ? AnnouncementStatus.active
                      : index == 1
                      ? AnnouncementStatus.scheduled
                      : AnnouncementStatus.archived;
                  provider.setFilterStatus(status);
                },
                tabs: [
                  Tab(text: 'Active'),
                  Tab(text: 'Scheduled'),
                  Tab(text: 'Archived'),
                ],
              ),
            ),
            // body: TabBarView(
            //   controller: _tabController,
            //   children: [
            //     _buildAnnouncementsList(context, provider),
            //     _buildAnnouncementsList(context, provider),
            //     _buildAnnouncementsList(context, provider),
            //   ],
            // ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAnnouncementsList(
                  context,
                  provider,
                  AnnouncementStatus.active,
                ),
                _buildAnnouncementsList(
                  context,
                  provider,
                  AnnouncementStatus.scheduled,
                ),
                _buildAnnouncementsList(
                  context,
                  provider,
                  AnnouncementStatus.archived,
                ),
              ],
            ),
            floatingActionButton: _userRole == 'admin'
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAnnouncementScreen(
                            schoolId: widget.schoolId,
                            userId: _userId!,
                            userRole: _userRole!,
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.add),
                  )
                : null,
          );
        },
      ),
    );
  }

  // Widget _buildAnnouncementsList(
  //   BuildContext context,
  //   AnnouncementsProvider provider,
  // ) {
  //   if (provider.isLoading) {
  //     return Center(child: CircularProgressIndicator());
  //   }

  //   if (provider.announcements.isEmpty) {
  //     return Center(child: Text('No announcements found'));
  //   }

  //   return ListView.builder(
  //     itemCount: provider.announcements.length,
  //     itemBuilder: (context, index) {
  //       final announcement = provider.announcements[index];
  //       return AnnouncementCard(
  //         announcement: announcement,
  //         userId: _userId!,
  //         userRole: _userRole!,
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => AnnouncementDetailScreen(
  //                 announcement: announcement,
  //                 userId: _userId!,
  //                 userRole: _userRole!,
  //                 schoolId: widget.schoolId,
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildAnnouncementsList(
    BuildContext context,
    AnnouncementsProvider provider,
    AnnouncementStatus status,
  ) {
    // Filter announcements by status
    final filteredAnnouncements = provider.announcements
        .where((announcement) => announcement.status == status)
        .toList();

    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (filteredAnnouncements.isEmpty) {
      return Center(child: Text('No ${status.name} announcements found'));
    }

    return ListView.builder(
      itemCount: filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = filteredAnnouncements[index];
        return AnnouncementCard(
          announcement: announcement,
          userId: _userId!,
          userRole: _userRole!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnnouncementDetailScreen(
                  announcement: announcement,
                  userId: _userId!,
                  userRole: _userRole!,
                  schoolId: widget.schoolId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Future<void> _fetchClasses() async {
  //   setState(() => _isLoadingClasses = true);

  //   try {
  //     final classesSnapshot = await FirebaseFirestore.instance
  //         .collection('schools')
  //         .doc(widget.schoolId)
  //         .collection('classes')
  //         .get();

  //     // DEBUG: Print what we found
  //     print(
  //       'Found ${classesSnapshot.docs.length} classes in school ${widget.schoolId}',
  //     );
  //     for (final doc in classesSnapshot.docs) {
  //       print('Class ID: ${doc.id}, Data: ${doc.data()}');
  //     }

  //     setState(() {
  //       _classMap.clear();
  //       _availableClasses = ['All Classes'];

  //       for (final doc in classesSnapshot.docs) {
  //         final data = doc.data();
  //         final className = data['name'] as String? ?? _formatClassId(doc.id);
  //         _classMap[doc.id] = className;
  //         _availableClasses.add(className);
  //       }

  //       // DEBUG: Print the final list
  //       print('Available classes: $_availableClasses');
  //     });
  //   } catch (e) {
  //     print('Error fetching classes: $e');
  //     setState(() {
  //       _availableClasses = ['All Classes'];
  //       _classMap = {};
  //     });
  //   } finally {
  //     setState(() => _isLoadingClasses = false);
  //   }
  // }
}

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final String userId;
  final String userRole;
  final VoidCallback onTap;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    required this.userId,
    required this.userRole,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRead =
        announcement.readReceipts[userId] != null &&
        announcement.readReceipts[userId]['read'] == true;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isRead ? Colors.grey[100] : null,
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Row(
          children: [
            if (announcement.isPinned)
              Icon(Icons.push_pin, size: 16, color: Colors.blue),
            if (announcement.priority == AnnouncementPriority.urgent)
              Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'URGENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                announcement.title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.body.length > 100
                  ? '${announcement.body.substring(0, 100)}...'
                  : announcement.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12),
                SizedBox(width: 4),
                Text(
                  DateFormat(
                    'MMM dd, yyyy - HH:mm',
                  ).format(announcement.createdAt),
                  style: TextStyle(fontSize: 12),
                ),
                if (announcement.attachments.isNotEmpty) ...[
                  SizedBox(width: 8),
                  Icon(Icons.attachment, size: 12),
                  SizedBox(width: 4),
                  Text(
                    '${announcement.attachments.length} attachment(s)',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (announcement.priority == AnnouncementPriority.urgent) {
      return CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.warning, color: Colors.white, size: 20),
      );
    } else if (announcement.isPinned) {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.push_pin, color: Colors.white, size: 20),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.announcement, color: Colors.white, size: 20),
      );
    }
  }
}

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;
  final String userId;
  final String userRole;
  final String schoolId;

  const AnnouncementDetailScreen({
    Key? key,
    required this.announcement,
    required this.userId,
    required this.userRole,
    required this.schoolId,
  }) : super(key: key);

  @override
  _AnnouncementDetailScreenState createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late bool _isRead;
  late bool _isAcknowledged;
  final AnnouncementsRepository _repository = AnnouncementsRepository(
    schoolId: '',
  );

  @override
  void initState() {
    super.initState();
    _repository.schoolId = widget.schoolId;

    _isRead =
        widget.announcement.readReceipts[widget.userId] != null &&
        widget.announcement.readReceipts[widget.userId]['read'] == true;

    _isAcknowledged =
        widget.announcement.readReceipts[widget.userId] != null &&
        widget.announcement.readReceipts[widget.userId]['acknowledged'] == true;

    // Mark as read if not already read
    if (!_isRead) {
      _repository.markAsRead(widget.announcement.id, widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Announcement'),
      //   actions: [
      //     if (widget.userRole == 'admin')
      //       IconButton(
      //         icon: Icon(Icons.edit),
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder: (context) => EditAnnouncementScreen(
      //                 announcement: widget.announcement,
      //                 schoolId: widget.schoolId,
      //                 userId: widget.userId,
      //               ),
      //             ),
      //           ).then((result) {
      //             // Refresh if announcement was updated
      //             if (result == true) {
      //               Navigator.pop(context, true);
      //             }
      //           });
      //         },
      //       ),
      //     if (widget.userRole == 'admin')
      //       IconButton(
      //         icon: Icon(Icons.delete),
      //         onPressed: () => _deleteAnnouncement(context),
      //       ),
      //   ],
      // ),
      appBar: AppBar(
        title: Text('Announcement'),
        actions: [
          if (widget.userRole == 'admin')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAnnouncementScreen(
                      announcement: widget.announcement,
                      schoolId: widget.schoolId,
                      userId: widget.userId,
                    ),
                  ),
                ).then((result) {
                  // Refresh if announcement was updated
                  if (result == true) {
                    Navigator.pop(context, true);
                  }
                });
              },
            ),
          if (widget.userRole == 'admin')
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteAnnouncement(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.announcement.isPinned)
              Row(
                children: [
                  Icon(Icons.push_pin, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Pinned',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (widget.announcement.priority == AnnouncementPriority.urgent)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'URGENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 16),
            Text(
              widget.announcement.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14),
                SizedBox(width: 4),
                Text(
                  DateFormat(
                    'MMM dd, yyyy - HH:mm',
                  ).format(widget.announcement.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(widget.announcement.body),
            SizedBox(height: 16),
            if (widget.announcement.attachments.isNotEmpty) ...[
              Divider(),
              Text(
                'Attachments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              ...widget.announcement.attachments.map(
                (attachment) => ListTile(
                  leading: _getAttachmentIcon(attachment.type),
                  title: Text(attachment.name),
                  subtitle: Text(
                    '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                  ),
                  onTap: () {
                    // Open attachment
                  },
                ),
              ),
            ],
            if (widget.userRole == 'admin') ...[
              Divider(),
              Text(
                'Read Receipts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              // Display read receipt statistics
              _buildReadReceiptsStats(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: widget.userRole != 'admin' && !_isAcknowledged
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    await _repository.acknowledgeAnnouncement(
                      widget.announcement.id,
                      widget.userId,
                    );
                    setState(() {
                      _isAcknowledged = true;
                    });
                  },
                  child: Text('Acknowledge'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildReadReceiptsStats() {
    final totalUsers = 100; // This should be fetched from your user count
    final readCount = widget.announcement.readReceipts.values
        .where((receipt) => receipt['read'] == true)
        .length;
    final acknowledgedCount = widget.announcement.readReceipts.values
        .where((receipt) => receipt['acknowledged'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Read: $readCount/$totalUsers (${(readCount / totalUsers * 100).toStringAsFixed(1)}%)',
        ),
        SizedBox(height: 4),
        Text(
          'Acknowledged: $acknowledgedCount/$totalUsers (${(acknowledgedCount / totalUsers * 100).toStringAsFixed(1)}%)',
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: readCount / totalUsers,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Icon _getAttachmentIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'image':
        return Icon(Icons.image, color: Colors.blue);
      case 'video':
        return Icon(Icons.videocam, color: Colors.purple);
      default:
        return Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  Future<void> _deleteAnnouncement(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Announcement'),
        content: Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteAnnouncement(widget.announcement.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement deleted successfully')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete announcement: $e')),
        );
      }
    }
  }
}

class CreateAnnouncementScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String userRole;

  const CreateAnnouncementScreen({
    Key? key,
    required this.schoolId,
    required this.userId,
    required this.userRole,
  }) : super(key: key);

  @override
  _CreateAnnouncementScreenState createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final AnnouncementsRepository _repository = AnnouncementsRepository(
    schoolId: '',
  );

  List<String> _selectedRoles = [];
  List<String> _selectedClasses = [];
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  bool _isPinned = false;
  List<XFile> _attachments = [];
  bool _isLoading = false;

  // Add these to your state class
  List<String> _availableClasses = [];
  Map<String, String> _classMap = {}; // Add this line
  String? _selectedClass;
  bool _isLoadingClasses = false;

  // These would be fetched from your database
  final List<String> _availableRoles = ['student', 'teacher', 'parent'];

  @override
  void initState() {
    super.initState();
    _repository.schoolId = widget.schoolId;
    _fetchClasses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Announcement'),
        actions: [IconButton(icon: Icon(Icons.send), onPressed: _submitForm)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter announcement content';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Target Audience',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableRoles.map((role) {
                        return FilterChip(
                          label: Text(role),
                          selected: _selectedRoles.contains(role),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRoles.add(role);
                              } else {
                                _selectedRoles.remove(role);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Target Classes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    _isLoadingClasses
                        ? CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value:
                                _selectedClass ??
                                'All Classes', // Set default value
                            decoration: InputDecoration(
                              labelText: 'Select Class',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableClasses.map((String className) {
                              return DropdownMenuItem<String>(
                                value: className,
                                child: Text(className),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedClass = newValue;

                                // Clear previous selections and add the new one
                                _selectedClasses.clear();
                                if (newValue != null &&
                                    newValue != 'All Classes') {
                                  // Find the class ID that matches the selected name
                                  final classEntry = _classMap.entries
                                      .firstWhere(
                                        (entry) => entry.value == newValue,
                                        orElse: () => MapEntry('', ''),
                                      );
                                  if (classEntry.key.isNotEmpty) {
                                    _selectedClasses.add(classEntry.key);
                                  }
                                } else if (newValue == 'All Classes') {
                                  // Select all class IDs
                                  _selectedClasses.addAll(
                                    _classMap.keys.toList(),
                                  );
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a class';
                              }
                              return null;
                            },
                          ),
                    SizedBox(height: 16),
                    Text(
                      'Priority',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Radio<AnnouncementPriority>(
                          value: AnnouncementPriority.normal,
                          groupValue: _priority,
                          onChanged: (value) {
                            setState(() {
                              _priority = value!;
                            });
                          },
                        ),
                        Text('Normal'),
                        SizedBox(width: 16),
                        Radio<AnnouncementPriority>(
                          value: AnnouncementPriority.urgent,
                          groupValue: _priority,
                          onChanged: (value) {
                            setState(() {
                              _priority = value!;
                            });
                          },
                        ),
                        Text('Urgent'),
                      ],
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Schedule for later'),
                      value: _isScheduled,
                      onChanged: (value) {
                        setState(() {
                          _isScheduled = value;
                        });
                      },
                    ),
                    if (_isScheduled) ...[
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );

                          if (selectedDate != null) {
                            final selectedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );

                            if (selectedTime != null) {
                              setState(() {
                                _scheduledDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Text(
                          _scheduledDate == null
                              ? 'Select Date & Time'
                              : 'Scheduled: ${DateFormat('MMM dd, yyyy - HH:mm').format(_scheduledDate!)}',
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Pin this announcement'),
                      value: _isPinned,
                      onChanged: (value) {
                        setState(() {
                          _isPinned = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Attachments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickFiles,
                      child: Text('Add Attachments'),
                    ),
                    SizedBox(height: 8),
                    ..._attachments.map(
                      (file) => ListTile(
                        leading: Icon(Icons.attachment),
                        title: Text(file.name),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _attachments.remove(file);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isNotEmpty) {
        setState(() {
          _attachments.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick files: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one target role')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload attachments
      final List<AnnouncementAttachment> uploadedAttachments = [];
      for (final file in _attachments) {
        final url = await _repository.uploadAttachment(file);
        uploadedAttachments.add(
          AnnouncementAttachment(
            url: url,
            name: file.name,
            type: file.mimeType?.split('/').first ?? 'other',
            size: (await file.length()).toInt(),
          ),
        );
      }

      // Create announcement
      final announcement = Announcement(
        id: '', // Will be generated by Firestore
        title: _titleController.text,
        body: _bodyController.text,
        attachments: uploadedAttachments,
        createdBy: widget.userId,
        targetAudience: {'roles': _selectedRoles, 'classes': _selectedClasses},
        priority: _priority,
        status: _isScheduled
            ? AnnouncementStatus.scheduled
            : AnnouncementStatus.active,
        isPinned: _isPinned,
        scheduledAt: _isScheduled ? _scheduledDate : null,
        expiresAt: _isScheduled
            ? null
            : DateTime.now().add(
                Duration(days: 30),
              ), // Auto-archive after 30 days
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        readReceipts: {},
      );

      await _repository.createAnnouncement(announcement);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement created successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create announcement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);

    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .get();

      setState(() {
        _classMap.clear();
        _availableClasses = ['All Classes'];

        for (final doc in classesSnapshot.docs) {
          final data = doc.data();
          final className = data['name'] as String? ?? _formatClassId(doc.id);
          _classMap[doc.id] = className;
          _availableClasses.add(className);
        }

        // Auto-select "All Classes" if we have classes
        if (_availableClasses.length > 1 && _selectedClasses.isEmpty) {
          _selectedClasses.addAll(_classMap.keys.toList());
        }
      });
    } catch (e) {
      print('Error fetching classes: $e');
      setState(() {
        _availableClasses = ['All Classes'];
        _classMap = {};
      });
    } finally {
      setState(() => _isLoadingClasses = false);
    }
  }

  String _formatClassId(String classId) {
    // Remove "class_" prefix and replace underscores with spaces
    String formatted = classId.replaceFirst('class_', '').replaceAll('_', ' ');
    // Capitalize first letter of each word
    formatted = formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
    return formatted;
  }
}

class AnnouncementsSearchDelegate extends SearchDelegate {
  final AnnouncementsProvider provider;

  AnnouncementsSearchDelegate(this.provider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    provider.setSearchQuery(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    provider.setSearchQuery(query);
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (provider.announcements.isEmpty) {
      return Center(child: Text('No announcements found'));
    }

    return ListView.builder(
      itemCount: provider.announcements.length,
      itemBuilder: (context, index) {
        final announcement = provider.announcements[index];
        return ListTile(
          title: Text(announcement.title),
          subtitle: Text(
            announcement.body.length > 100
                ? '${announcement.body.substring(0, 100)}...'
                : announcement.body,
          ),
          onTap: () {
            // Navigate to announcement detail
          },
        );
      },
    );
  }
}
