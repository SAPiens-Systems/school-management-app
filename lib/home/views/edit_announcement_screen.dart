import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/home/views/announcement_creation_screen.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final Announcement announcement;
  final String schoolId;
  final String userId;

  const EditAnnouncementScreen({
    Key? key,
    required this.announcement,
    required this.schoolId,
    required this.userId,
  }) : super(key: key);

  @override
  _EditAnnouncementScreenState createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  late AnnouncementsRepository _repository;

  List<String> _selectedRoles = [];
  List<String> _selectedClasses = [];
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  bool _isPinned = false;
  List<XFile> _newAttachments = [];
  List<AnnouncementAttachment> _existingAttachments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = AnnouncementsRepository(schoolId: widget.schoolId);

    // Pre-fill form with existing data
    _titleController.text = widget.announcement.title;
    _bodyController.text = widget.announcement.body;
    _selectedRoles = List<String>.from(
      widget.announcement.targetAudience['roles'] ?? [],
    );
    _selectedClasses = List<String>.from(
      widget.announcement.targetAudience['classes'] ?? [],
    );
    _priority = widget.announcement.priority;
    _isPinned = widget.announcement.isPinned;
    _existingAttachments = widget.announcement.attachments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Announcement'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _submitForm)],
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
                      children: ['student', 'teacher', 'parent'].map((role) {
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
                      child: Text('Add New Attachments'),
                    ),
                    SizedBox(height: 8),
                    ..._existingAttachments.map(
                      (attachment) => ListTile(
                        leading: _getAttachmentIcon(attachment.type),
                        title: Text(attachment.name),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _existingAttachments.remove(attachment);
                            });
                          },
                        ),
                      ),
                    ),
                    ..._newAttachments.map(
                      (file) => ListTile(
                        leading: Icon(Icons.attachment),
                        title: Text(file.name),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _newAttachments.remove(file);
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
          _newAttachments.addAll(files);
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new attachments
      final List<AnnouncementAttachment> uploadedAttachments = [];
      for (final file in _newAttachments) {
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

      // Combine existing and new attachments
      final allAttachments = [..._existingAttachments, ...uploadedAttachments];

      // Create updated announcement
      final updatedAnnouncement = Announcement(
        id: widget.announcement.id,
        title: _titleController.text,
        body: _bodyController.text,
        attachments: allAttachments,
        createdBy: widget.userId,
        targetAudience: {'roles': _selectedRoles, 'classes': _selectedClasses},
        priority: _priority,
        status: widget.announcement.status,
        isPinned: _isPinned,
        scheduledAt: widget.announcement.scheduledAt,
        expiresAt: widget.announcement.expiresAt,
        createdAt: widget.announcement.createdAt,
        updatedAt: DateTime.now(),
        readReceipts: widget.announcement.readReceipts,
      );

      await _repository.updateAnnouncement(updatedAnnouncement);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update announcement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
}
